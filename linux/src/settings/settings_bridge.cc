#include "settings/settings_bridge.h"

#include <cstring>

namespace {

const char* kSettingsChannelName = "libadwaitter/settings";

static gboolean get_system_enable_animations() {
  GtkSettings *settings = gtk_settings_get_default();
  if (settings != nullptr) {
    gboolean enabled = TRUE;
    g_object_get(settings, "gtk-enable-animations", &enabled, NULL);
    return enabled;
  }
  GSettingsSchemaSource *source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) schema = g_settings_schema_source_lookup(
        source, "org.gnome.desktop.interface", TRUE);
    if (schema != nullptr &&
        g_settings_schema_has_key(schema, "enable-animations")) {
      g_autoptr(GSettings) gsettings =
          g_settings_new("org.gnome.desktop.interface");
      return g_settings_get_boolean(gsettings, "enable-animations");
    }
  }
  return TRUE;
}

static gdouble get_system_duration_factor() {
  const gchar *current_desktop = g_getenv("XDG_CURRENT_DESKTOP");
  if (current_desktop != nullptr && strstr(current_desktop, "KDE") != nullptr) {
    const gchar *config_dir = g_get_user_config_dir();
    g_autofree gchar *path =
        g_build_filename(config_dir, "kdeglobals", nullptr);
    g_autoptr(GKeyFile) key_file = g_key_file_new();
    if (g_key_file_load_from_file(key_file, path, G_KEY_FILE_NONE, nullptr)) {
      GError *error = nullptr;
      gdouble factor = g_key_file_get_double(key_file, "KDE",
                                             "AnimationDurationFactor", &error);
      if (error == nullptr) {
        return factor;
      }
      g_clear_error(&error);
    }
  }
  return 1.0;
}

static FlValue *build_animation_settings_map() {
  FlValue *map = fl_value_new_map();
  fl_value_set_string_take(map, "enableAnimations",
                           fl_value_new_bool(get_system_enable_animations()));
  fl_value_set_string_take(map, "durationFactor",
                           fl_value_new_float(get_system_duration_factor()));
  const gchar *current_desktop = g_getenv("XDG_CURRENT_DESKTOP");
  fl_value_set_string_take(map, "desktop",
                           fl_value_new_string(current_desktop != nullptr
                                                   ? current_desktop
                                                   : "GNOME"));
  return map;
}

static gchar *get_window_button_layout() {
  GSettingsSchemaSource *source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) wm_schema = g_settings_schema_source_lookup(
        source, "org.gnome.desktop.wm.preferences", TRUE);
    if (wm_schema != nullptr &&
        g_settings_schema_has_key(wm_schema, "button-layout")) {
      g_autoptr(GSettings) wm_settings =
          g_settings_new("org.gnome.desktop.wm.preferences");
      gchar *layout = g_settings_get_string(wm_settings, "button-layout");
      if (layout != nullptr && layout[0] != '\0') {
        return layout;
      }
      g_free(layout);
    }
  }

  GtkSettings *settings = gtk_settings_get_default();
  if (settings != nullptr) {
    gchar *gtk_layout = nullptr;
    g_object_get(settings, "gtk-decoration-layout", &gtk_layout, NULL);
    if (gtk_layout != nullptr && gtk_layout[0] != '\0') {
      return gtk_layout;
    }
    g_free(gtk_layout);
  }

  return g_strdup(":close");
}

static void on_wm_button_layout_changed(GSettings *settings, const gchar *key,
                                        gpointer user_data) {
  FlMethodChannel *channel = FL_METHOD_CHANNEL(user_data);
  g_autofree gchar *layout = get_window_button_layout();
  g_autoptr(FlValue) val = fl_value_new_string(layout);
  fl_method_channel_invoke_method(channel, "onWindowButtonLayoutChanged", val,
                                  nullptr, nullptr, nullptr);
}

static void on_gtk_decoration_layout_changed(GObject *object, GParamSpec *pspec,
                                             gpointer user_data) {
  FlMethodChannel *channel = FL_METHOD_CHANNEL(user_data);
  g_autofree gchar *layout = get_window_button_layout();
  g_autoptr(FlValue) val = fl_value_new_string(layout);
  fl_method_channel_invoke_method(channel, "onWindowButtonLayoutChanged", val,
                                  nullptr, nullptr, nullptr);
}

static void on_gtk_animations_changed(GObject *object, GParamSpec *pspec,
                                      gpointer user_data) {
  FlMethodChannel *channel = FL_METHOD_CHANNEL(user_data);
  g_autoptr(FlValue) map = build_animation_settings_map();
  fl_method_channel_invoke_method(channel, "onAnimationSettingsChanged", map,
                                  nullptr, nullptr, nullptr);
}

static void settings_method_call_handler(FlMethodChannel *channel,
                                         FlMethodCall *method_call,
                                         gpointer user_data) {
  const gchar *method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getAnimationSettings") == 0) {
    g_autoptr(FlValue) map = build_animation_settings_map();
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "getWindowButtonLayout") == 0) {
    g_autofree gchar *layout = get_window_button_layout();
    g_autoptr(FlValue) val = fl_value_new_string(layout);
    fl_method_call_respond_success(method_call, val, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

}  // namespace

namespace libadwaitter {

void RegisterSettingsBridge(FlPluginRegistrar* registrar, GtkWindow* window) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* settings_channel = fl_method_channel_new(
      messenger, kSettingsChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(settings_channel,
                                            settings_method_call_handler,
                                            settings_channel, nullptr);

  GSettingsSchemaSource* schema_source = g_settings_schema_source_get_default();
  if (schema_source != nullptr) {
    g_autoptr(GSettingsSchema) wm_schema = g_settings_schema_source_lookup(
        schema_source, "org.gnome.desktop.wm.preferences", TRUE);
    if (wm_schema != nullptr &&
        g_settings_schema_has_key(wm_schema, "button-layout")) {
      GSettings* wm_settings =
          g_settings_new("org.gnome.desktop.wm.preferences");
      g_object_set_data_full(G_OBJECT(window), "libadwaitter-wm-gsettings",
                             wm_settings, g_object_unref);
      g_signal_connect(wm_settings, "changed::button-layout",
                       G_CALLBACK(on_wm_button_layout_changed),
                       settings_channel);
      g_free(g_settings_get_string(wm_settings, "button-layout"));
    }
  }

  GtkSettings* default_settings = gtk_settings_get_default();
  if (default_settings != nullptr) {
    g_signal_connect(default_settings, "notify::gtk-enable-animations",
                     G_CALLBACK(on_gtk_animations_changed), settings_channel);
    g_signal_connect(default_settings, "notify::gtk-decoration-layout",
                     G_CALLBACK(on_gtk_decoration_layout_changed),
                     settings_channel);
  }
}

}  // namespace libadwaitter
