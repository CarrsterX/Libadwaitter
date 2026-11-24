#include "style/style_bridge.h"

#include <cstring>

namespace {

const char* kStyleChannelName = "libadwaitter/style";

struct StyleBridgeState {
  FlMethodChannel *channel = nullptr;
  GSettings *interface_settings = nullptr;
  GSettings *a11y_settings = nullptr;
  GDBusConnection *bus = nullptr;
  guint portal_sub_id = 0;
  gboolean has_portal_scheme = FALSE;
  gchar *portal_color_scheme = nullptr;
  gboolean has_portal_contrast = FALSE;
  gboolean portal_high_contrast = FALSE;
};

static void style_bridge_state_free(gpointer data) {
  StyleBridgeState *state = static_cast<StyleBridgeState *>(data);
  if (state == nullptr)
    return;
  if (state->bus != nullptr && state->portal_sub_id != 0) {
    g_dbus_connection_signal_unsubscribe(state->bus, state->portal_sub_id);
  }
  g_clear_object(&state->bus);
  g_clear_object(&state->interface_settings);
  g_clear_object(&state->a11y_settings);
  g_clear_object(&state->channel);
  g_clear_pointer(&state->portal_color_scheme, g_free);
  g_free(state);
}

static const gchar *portal_color_scheme_to_string(guint32 value) {
  switch (value) {
  case 1:
    return "prefer-dark";
  case 2:
    return "prefer-light";
  default:
    return "default";
  }
}

static FlValue *build_system_appearance_map(StyleBridgeState *state) {
  FlValue *map = fl_value_new_map();
  g_autofree gchar *color_scheme = g_strdup("default");
  g_autofree gchar *accent_color = g_strdup("blue");
  gboolean high_contrast = FALSE;

  GSettingsSchemaSource *source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) schema = g_settings_schema_source_lookup(
        source, "org.gnome.desktop.interface", TRUE);
    if (schema != nullptr) {
      g_autoptr(GSettings) gsettings =
          g_settings_new("org.gnome.desktop.interface");
      if (g_settings_schema_has_key(schema, "color-scheme")) {
        g_free(color_scheme);
        color_scheme = g_settings_get_string(gsettings, "color-scheme");
      } else if (g_settings_schema_has_key(schema, "gtk-theme")) {
        g_autofree gchar *gtk_theme =
            g_settings_get_string(gsettings, "gtk-theme");
        if (gtk_theme != nullptr && g_str_has_suffix(gtk_theme, "-dark")) {
          g_free(color_scheme);
          color_scheme = g_strdup("prefer-dark");
        }
      }
      if (g_settings_schema_has_key(schema, "accent-color")) {
        g_free(accent_color);
        accent_color = g_settings_get_string(gsettings, "accent-color");
      }
    }

    g_autoptr(GSettingsSchema) a11y_schema = g_settings_schema_source_lookup(
        source, "org.gnome.desktop.a11y.interface", TRUE);
    if (a11y_schema != nullptr &&
        g_settings_schema_has_key(a11y_schema, "high-contrast")) {
      g_autoptr(GSettings) a11y_settings =
          g_settings_new("org.gnome.desktop.a11y.interface");
      high_contrast = g_settings_get_boolean(a11y_settings, "high-contrast");
    }
  }

  if (state != nullptr) {
    if (state->has_portal_scheme && state->portal_color_scheme != nullptr) {
      g_free(color_scheme);
      color_scheme = g_strdup(state->portal_color_scheme);
    }
    if (state->has_portal_contrast) {
      high_contrast = state->portal_high_contrast;
    }
  }

  fl_value_set_string_take(map, "colorScheme",
                           fl_value_new_string(color_scheme));
  fl_value_set_string_take(map, "accentColor",
                           fl_value_new_string(accent_color));
  fl_value_set_string_take(map, "highContrast",
                           fl_value_new_bool(high_contrast));
  return map;
}

static void emit_system_appearance_changed(StyleBridgeState *state) {
  if (state == nullptr || state->channel == nullptr)
    return;
  g_autoptr(FlValue) map = build_system_appearance_map(state);
  fl_method_channel_invoke_method(state->channel, "onSystemAppearanceChanged",
                                  map, nullptr, nullptr, nullptr);
}

static void on_gsettings_appearance_changed(GSettings *settings,
                                            const gchar *key,
                                            gpointer user_data) {
  StyleBridgeState *state = static_cast<StyleBridgeState *>(user_data);
  if (state == nullptr)
    return;
  // GSettings updated directly (e.g. via gsettings CLI); clear stale portal
  // override for color-scheme
  if (g_strcmp0(key, "color-scheme") == 0) {
    state->has_portal_scheme = FALSE;
    g_clear_pointer(&state->portal_color_scheme, g_free);
  } else if (g_strcmp0(key, "high-contrast") == 0) {
    state->has_portal_contrast = FALSE;
  }
  emit_system_appearance_changed(state);
}

static void
on_portal_setting_changed(GDBusConnection *connection, const gchar *sender_name,
                          const gchar *object_path, const gchar *interface_name,
                          const gchar *signal_name, GVariant *parameters,
                          gpointer user_data) {
  StyleBridgeState *state = static_cast<StyleBridgeState *>(user_data);
  if (state == nullptr || parameters == nullptr)
    return;

  const gchar *ns = nullptr;
  const gchar *key = nullptr;
  g_autoptr(GVariant) value = nullptr;
  g_variant_get(parameters, "(&s&sv)", &ns, &key, &value);
  if (g_strcmp0(ns, "org.freedesktop.appearance") != 0 || value == nullptr) {
    return;
  }

  if (g_strcmp0(key, "color-scheme") == 0 &&
      g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    guint32 scheme_val = g_variant_get_uint32(value);
    g_free(state->portal_color_scheme);
    state->portal_color_scheme =
        g_strdup(portal_color_scheme_to_string(scheme_val));
    state->has_portal_scheme = TRUE;
    emit_system_appearance_changed(state);
  } else if (g_strcmp0(key, "contrast") == 0 &&
             g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    state->portal_high_contrast = g_variant_get_uint32(value) == 1;
    state->has_portal_contrast = TRUE;
    emit_system_appearance_changed(state);
  }
}

static void on_portal_read_color_scheme_done(GObject *source_object,
                                             GAsyncResult *res,
                                             gpointer user_data) {
  GWeakRef *weak_window = static_cast<GWeakRef *>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_finish(
      G_DBUS_CONNECTION(source_object), res, &error);
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_weak_ref_get(weak_window));
  g_weak_ref_clear(weak_window);
  g_free(weak_window);

  if (error != nullptr || result == nullptr || window == nullptr) {
    return;
  }

  StyleBridgeState *state = static_cast<StyleBridgeState *>(
      g_object_get_data(G_OBJECT(window), "libadwaitter-style-bridge"));
  if (state == nullptr)
    return;

  g_autoptr(GVariant) outer_variant = nullptr;
  g_variant_get(result, "(v)", &outer_variant);
  if (outer_variant != nullptr &&
      g_variant_is_of_type(outer_variant, G_VARIANT_TYPE_VARIANT)) {
    g_autoptr(GVariant) inner = g_variant_get_variant(outer_variant);
    if (inner != nullptr &&
        g_variant_is_of_type(inner, G_VARIANT_TYPE_UINT32)) {
      guint32 scheme_val = g_variant_get_uint32(inner);
      g_free(state->portal_color_scheme);
      state->portal_color_scheme =
          g_strdup(portal_color_scheme_to_string(scheme_val));
      state->has_portal_scheme = TRUE;
      emit_system_appearance_changed(state);
    }
  }
}

static void on_session_bus_ready(GObject *source_object, GAsyncResult *res,
                                 gpointer user_data) {
  GWeakRef *weak_window = static_cast<GWeakRef *>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) bus = g_bus_get_finish(res, &error);
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_weak_ref_get(weak_window));
  g_weak_ref_clear(weak_window);
  g_free(weak_window);

  if (error != nullptr || bus == nullptr || window == nullptr) {
    return;
  }

  StyleBridgeState *state = static_cast<StyleBridgeState *>(
      g_object_get_data(G_OBJECT(window), "libadwaitter-style-bridge"));
  if (state == nullptr)
    return;

  state->bus = G_DBUS_CONNECTION(g_object_ref(bus));
  state->portal_sub_id = g_dbus_connection_signal_subscribe(
      state->bus, "org.freedesktop.portal.Desktop",
      "org.freedesktop.portal.Settings", "SettingChanged",
      "/org/freedesktop/portal/desktop", "org.freedesktop.appearance",
      G_DBUS_SIGNAL_FLAGS_NONE, on_portal_setting_changed, state, nullptr);

  GWeakRef *read_weak_window = g_new(GWeakRef, 1);
  g_weak_ref_init(read_weak_window, window);
  g_dbus_connection_call(
      state->bus, "org.freedesktop.portal.Desktop",
      "/org/freedesktop/portal/desktop", "org.freedesktop.portal.Settings",
      "Read",
      g_variant_new("(ss)", "org.freedesktop.appearance", "color-scheme"),
      G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NONE, -1, nullptr,
      on_portal_read_color_scheme_done, read_weak_window);
}

static gchar *g_cached_emoji_font_path = nullptr;

static const gchar *resolve_system_emoji_font_path() {
  if (g_cached_emoji_font_path != nullptr) {
    return g_cached_emoji_font_path;
  }
  g_autofree gchar *out = nullptr;
  gint status = 0;
  if (g_spawn_command_line_sync("fc-match --format=%{file} emoji:color=true",
                                &out, nullptr, &status, nullptr) &&
      status == 0 && out != nullptr) {
    g_strstrip(out);
    if (out[0] != '\0' && g_file_test(out, G_FILE_TEST_EXISTS)) {
      g_cached_emoji_font_path = g_strdup(out);
      return g_cached_emoji_font_path;
    }
  }
  static const char *kFallbackPaths[] = {
      "/usr/share/fonts/google-noto-color-emoji-fonts/Noto-COLRv1.ttf",
      "/usr/share/fonts/google-noto-color-emoji-fonts/NotoColorEmoji.ttf",
      "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf",
      "/usr/share/fonts/noto/NotoColorEmoji.ttf",
  };
  for (size_t i = 0; i < G_N_ELEMENTS(kFallbackPaths); ++i) {
    if (g_file_test(kFallbackPaths[i], G_FILE_TEST_EXISTS)) {
      g_cached_emoji_font_path = g_strdup(kFallbackPaths[i]);
      return g_cached_emoji_font_path;
    }
  }
  return nullptr;
}

static void style_method_call_handler(FlMethodChannel *channel,
                                      FlMethodCall *method_call,
                                      gpointer user_data) {
  StyleBridgeState *state = static_cast<StyleBridgeState *>(user_data);
  const gchar *method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getSystemAppearance") == 0) {
    g_autoptr(FlValue) map = build_system_appearance_map(state);
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "getSystemEmojiFontPath") == 0) {
    const gchar *path = resolve_system_emoji_font_path();
    g_autoptr(FlValue) val =
        path != nullptr ? fl_value_new_string(path) : fl_value_new_null();
    fl_method_call_respond_success(method_call, val, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

}  // namespace

namespace libadwaitter {

void RegisterStyleBridge(FlPluginRegistrar* registrar, GtkWindow* window) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* style_channel = fl_method_channel_new(
      messenger, kStyleChannelName, FL_METHOD_CODEC(codec));
  StyleBridgeState* style_state = g_new0(StyleBridgeState, 1);
  style_state->channel = style_channel;
  g_object_set_data_full(G_OBJECT(window), "libadwaitter-style-bridge",
                         style_state, style_bridge_state_free);
  fl_method_channel_set_method_call_handler(
      style_channel, style_method_call_handler, style_state, nullptr);

  GSettingsSchemaSource* schema_source = g_settings_schema_source_get_default();
  if (schema_source != nullptr) {
    g_autoptr(GSettingsSchema) interface_schema =
        g_settings_schema_source_lookup(schema_source,
                                        "org.gnome.desktop.interface", TRUE);
    if (interface_schema != nullptr) {
      style_state->interface_settings =
          g_settings_new("org.gnome.desktop.interface");
      if (g_settings_schema_has_key(interface_schema, "color-scheme")) {
        g_signal_connect(
            style_state->interface_settings, "changed::color-scheme",
            G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings,
                                     "color-scheme"));
      } else if (g_settings_schema_has_key(interface_schema, "gtk-theme")) {
        g_signal_connect(style_state->interface_settings, "changed::gtk-theme",
                         G_CALLBACK(on_gsettings_appearance_changed),
                         style_state);
        g_free(g_settings_get_string(style_state->interface_settings,
                                     "gtk-theme"));
      }
      if (g_settings_schema_has_key(interface_schema, "accent-color")) {
        g_signal_connect(
            style_state->interface_settings, "changed::accent-color",
            G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings,
                                     "accent-color"));
      }
    }

    g_autoptr(GSettingsSchema) a11y_schema = g_settings_schema_source_lookup(
        schema_source, "org.gnome.desktop.a11y.interface", TRUE);
    if (a11y_schema != nullptr &&
        g_settings_schema_has_key(a11y_schema, "high-contrast")) {
      style_state->a11y_settings =
          g_settings_new("org.gnome.desktop.a11y.interface");
      g_signal_connect(style_state->a11y_settings, "changed::high-contrast",
                       G_CALLBACK(on_gsettings_appearance_changed),
                       style_state);
      (void)g_settings_get_boolean(style_state->a11y_settings, "high-contrast");
    }
  }

  GWeakRef* weak_window = g_new(GWeakRef, 1);
  g_weak_ref_init(weak_window, window);
  g_bus_get(G_BUS_TYPE_SESSION, nullptr, on_session_bus_ready, weak_window);
}

}  // namespace libadwaitter
