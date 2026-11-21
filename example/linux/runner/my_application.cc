#include "my_application.h"

#include <flutter_linux/flutter_linux.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

const char* kWindowChannelName = "libadwaitter/window";
const char* kSettingsChannelName = "libadwaitter/settings";
const char* kStyleChannelName = "libadwaitter/style";
const char* kPortalChannelName = "libadwaitter/portal";

static gboolean get_system_enable_animations() {
  GtkSettings* settings = gtk_settings_get_default();
  if (settings != nullptr) {
    gboolean enabled = TRUE;
    g_object_get(settings, "gtk-enable-animations", &enabled, NULL);
    return enabled;
  }
  GSettingsSchemaSource* source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.interface", TRUE);
    if (schema != nullptr && g_settings_schema_has_key(schema, "enable-animations")) {
      g_autoptr(GSettings) gsettings = g_settings_new("org.gnome.desktop.interface");
      return g_settings_get_boolean(gsettings, "enable-animations");
    }
  }
  return TRUE;
}

static gdouble get_system_duration_factor() {
  const gchar* current_desktop = g_getenv("XDG_CURRENT_DESKTOP");
  if (current_desktop != nullptr && strstr(current_desktop, "KDE") != nullptr) {
    const gchar* config_dir = g_get_user_config_dir();
    g_autofree gchar* path = g_build_filename(config_dir, "kdeglobals", nullptr);
    g_autoptr(GKeyFile) key_file = g_key_file_new();
    if (g_key_file_load_from_file(key_file, path, G_KEY_FILE_NONE, nullptr)) {
      GError* error = nullptr;
      gdouble factor = g_key_file_get_double(key_file, "KDE", "AnimationDurationFactor", &error);
      if (error == nullptr) {
        return factor;
      }
      g_clear_error(&error);
    }
  }
  return 1.0;
}

static FlValue* build_animation_settings_map() {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "enableAnimations",
                           fl_value_new_bool(get_system_enable_animations()));
  fl_value_set_string_take(map, "durationFactor",
                           fl_value_new_float(get_system_duration_factor()));
  const gchar* current_desktop = g_getenv("XDG_CURRENT_DESKTOP");
  fl_value_set_string_take(map, "desktop",
                           fl_value_new_string(current_desktop != nullptr ? current_desktop : "GNOME"));
  return map;
}

static gchar* get_window_button_layout() {
  GSettingsSchemaSource* source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) wm_schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.wm.preferences", TRUE);
    if (wm_schema != nullptr && g_settings_schema_has_key(wm_schema, "button-layout")) {
      g_autoptr(GSettings) wm_settings = g_settings_new("org.gnome.desktop.wm.preferences");
      gchar* layout = g_settings_get_string(wm_settings, "button-layout");
      if (layout != nullptr && layout[0] != '\0') {
        return layout;
      }
      g_free(layout);
    }
  }

  GtkSettings* settings = gtk_settings_get_default();
  if (settings != nullptr) {
    gchar* gtk_layout = nullptr;
    g_object_get(settings, "gtk-decoration-layout", &gtk_layout, NULL);
    if (gtk_layout != nullptr && gtk_layout[0] != '\0') {
      return gtk_layout;
    }
    g_free(gtk_layout);
  }

  return g_strdup(":close");
}

static void on_wm_button_layout_changed(GSettings* settings, const gchar* key, gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  g_autofree gchar* layout = get_window_button_layout();
  g_autoptr(FlValue) val = fl_value_new_string(layout);
  fl_method_channel_invoke_method(channel, "onWindowButtonLayoutChanged", val,
                                  nullptr, nullptr, nullptr);
}

static void on_gtk_decoration_layout_changed(GObject* object, GParamSpec* pspec, gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  g_autofree gchar* layout = get_window_button_layout();
  g_autoptr(FlValue) val = fl_value_new_string(layout);
  fl_method_channel_invoke_method(channel, "onWindowButtonLayoutChanged", val,
                                  nullptr, nullptr, nullptr);
}

static void on_gtk_animations_changed(GObject* object, GParamSpec* pspec, gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  g_autoptr(FlValue) map = build_animation_settings_map();
  fl_method_channel_invoke_method(channel, "onAnimationSettingsChanged", map, nullptr, nullptr, nullptr);
}

static void settings_method_call_handler(FlMethodChannel* channel,
                                         FlMethodCall* method_call,
                                         gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getAnimationSettings") == 0) {
    g_autoptr(FlValue) map = build_animation_settings_map();
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "getWindowButtonLayout") == 0) {
    g_autofree gchar* layout = get_window_button_layout();
    g_autoptr(FlValue) val = fl_value_new_string(layout);
    fl_method_call_respond_success(method_call, val, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

struct StyleBridgeState {
  FlMethodChannel* channel = nullptr;
  GSettings* interface_settings = nullptr;
  GSettings* a11y_settings = nullptr;
  GDBusConnection* bus = nullptr;
  guint portal_sub_id = 0;
  gboolean has_portal_scheme = FALSE;
  gchar* portal_color_scheme = nullptr;
  gboolean has_portal_contrast = FALSE;
  gboolean portal_high_contrast = FALSE;
};

static void style_bridge_state_free(gpointer data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(data);
  if (state == nullptr) return;
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

static const gchar* portal_color_scheme_to_string(guint32 value) {
  switch (value) {
    case 1:
      return "prefer-dark";
    case 2:
      return "prefer-light";
    default:
      return "default";
  }
}

static FlValue* build_system_appearance_map(StyleBridgeState* state) {
  FlValue* map = fl_value_new_map();
  g_autofree gchar* color_scheme = g_strdup("default");
  g_autofree gchar* accent_color = g_strdup("blue");
  gboolean high_contrast = FALSE;

  GSettingsSchemaSource* source = g_settings_schema_source_get_default();
  if (source != nullptr) {
    g_autoptr(GSettingsSchema) schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.interface", TRUE);
    if (schema != nullptr) {
      g_autoptr(GSettings) gsettings = g_settings_new("org.gnome.desktop.interface");
      if (g_settings_schema_has_key(schema, "color-scheme")) {
        g_free(color_scheme);
        color_scheme = g_settings_get_string(gsettings, "color-scheme");
      } else if (g_settings_schema_has_key(schema, "gtk-theme")) {
        g_autofree gchar* gtk_theme = g_settings_get_string(gsettings, "gtk-theme");
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

    g_autoptr(GSettingsSchema) a11y_schema =
        g_settings_schema_source_lookup(source, "org.gnome.desktop.a11y.interface", TRUE);
    if (a11y_schema != nullptr && g_settings_schema_has_key(a11y_schema, "high-contrast")) {
      g_autoptr(GSettings) a11y_settings = g_settings_new("org.gnome.desktop.a11y.interface");
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

  fl_value_set_string_take(map, "colorScheme", fl_value_new_string(color_scheme));
  fl_value_set_string_take(map, "accentColor", fl_value_new_string(accent_color));
  fl_value_set_string_take(map, "highContrast", fl_value_new_bool(high_contrast));
  return map;
}

static void emit_system_appearance_changed(StyleBridgeState* state) {
  if (state == nullptr || state->channel == nullptr) return;
  g_autoptr(FlValue) map = build_system_appearance_map(state);
  fl_method_channel_invoke_method(state->channel, "onSystemAppearanceChanged", map,
                                  nullptr, nullptr, nullptr);
}

static void on_gsettings_appearance_changed(GSettings* settings, const gchar* key, gpointer user_data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(user_data);
  if (state == nullptr) return;
  // GSettings updated directly (e.g. via gsettings CLI); clear stale portal override for color-scheme
  if (g_strcmp0(key, "color-scheme") == 0) {
    state->has_portal_scheme = FALSE;
    g_clear_pointer(&state->portal_color_scheme, g_free);
  } else if (g_strcmp0(key, "high-contrast") == 0) {
    state->has_portal_contrast = FALSE;
  }
  emit_system_appearance_changed(state);
}

static void on_portal_setting_changed(GDBusConnection* connection,
                                      const gchar* sender_name,
                                      const gchar* object_path,
                                      const gchar* interface_name,
                                      const gchar* signal_name,
                                      GVariant* parameters,
                                      gpointer user_data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(user_data);
  if (state == nullptr || parameters == nullptr) return;

  const gchar* ns = nullptr;
  const gchar* key = nullptr;
  g_autoptr(GVariant) value = nullptr;
  g_variant_get(parameters, "(&s&sv)", &ns, &key, &value);
  if (g_strcmp0(ns, "org.freedesktop.appearance") != 0 || value == nullptr) {
    return;
  }

  if (g_strcmp0(key, "color-scheme") == 0 && g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    guint32 scheme_val = g_variant_get_uint32(value);
    g_free(state->portal_color_scheme);
    state->portal_color_scheme = g_strdup(portal_color_scheme_to_string(scheme_val));
    state->has_portal_scheme = TRUE;
    emit_system_appearance_changed(state);
  } else if (g_strcmp0(key, "contrast") == 0 && g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    state->portal_high_contrast = g_variant_get_uint32(value) == 1;
    state->has_portal_contrast = TRUE;
    emit_system_appearance_changed(state);
  }
}

static void on_portal_read_color_scheme_done(GObject* source_object,
                                             GAsyncResult* res,
                                             gpointer user_data) {
  GWeakRef* weak_window = static_cast<GWeakRef*>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_finish(G_DBUS_CONNECTION(source_object), res, &error);
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_weak_ref_get(weak_window));
  g_weak_ref_clear(weak_window);
  g_free(weak_window);

  if (error != nullptr || result == nullptr || window == nullptr) {
    return;
  }

  StyleBridgeState* state =
      static_cast<StyleBridgeState*>(g_object_get_data(G_OBJECT(window), "libadwaitter-style-bridge"));
  if (state == nullptr) return;

  g_autoptr(GVariant) outer_variant = nullptr;
  g_variant_get(result, "(v)", &outer_variant);
  if (outer_variant != nullptr && g_variant_is_of_type(outer_variant, G_VARIANT_TYPE_VARIANT)) {
    g_autoptr(GVariant) inner = g_variant_get_variant(outer_variant);
    if (inner != nullptr && g_variant_is_of_type(inner, G_VARIANT_TYPE_UINT32)) {
      guint32 scheme_val = g_variant_get_uint32(inner);
      g_free(state->portal_color_scheme);
      state->portal_color_scheme = g_strdup(portal_color_scheme_to_string(scheme_val));
      state->has_portal_scheme = TRUE;
      emit_system_appearance_changed(state);
    }
  }
}

static void on_session_bus_ready(GObject* source_object, GAsyncResult* res, gpointer user_data) {
  GWeakRef* weak_window = static_cast<GWeakRef*>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) bus = g_bus_get_finish(res, &error);
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_weak_ref_get(weak_window));
  g_weak_ref_clear(weak_window);
  g_free(weak_window);

  if (error != nullptr || bus == nullptr || window == nullptr) {
    return;
  }

  StyleBridgeState* state =
      static_cast<StyleBridgeState*>(g_object_get_data(G_OBJECT(window), "libadwaitter-style-bridge"));
  if (state == nullptr) return;

  state->bus = G_DBUS_CONNECTION(g_object_ref(bus));
  state->portal_sub_id = g_dbus_connection_signal_subscribe(
      state->bus,
      "org.freedesktop.portal.Desktop",
      "org.freedesktop.portal.Settings",
      "SettingChanged",
      "/org/freedesktop/portal/desktop",
      "org.freedesktop.appearance",
      G_DBUS_SIGNAL_FLAGS_NONE,
      on_portal_setting_changed,
      state,
      nullptr);

  GWeakRef* read_weak_window = g_new(GWeakRef, 1);
  g_weak_ref_init(read_weak_window, window);
  g_dbus_connection_call(
      state->bus,
      "org.freedesktop.portal.Desktop",
      "/org/freedesktop/portal/desktop",
      "org.freedesktop.portal.Settings",
      "Read",
      g_variant_new("(ss)", "org.freedesktop.appearance", "color-scheme"),
      G_VARIANT_TYPE("(v)"),
      G_DBUS_CALL_FLAGS_NONE,
      -1,
      nullptr,
      on_portal_read_color_scheme_done,
      read_weak_window);
}

static void style_method_call_handler(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  StyleBridgeState* state = static_cast<StyleBridgeState*>(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getSystemAppearance") == 0) {
    g_autoptr(FlValue) map = build_system_appearance_map(state);
    fl_method_call_respond_success(method_call, map, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static GHashTable* g_windows_by_view_id = nullptr;

static gboolean window_draw_cb(GtkWidget* widget, cairo_t* cr, gpointer user_data);

static void on_sub_window_destroyed(GtkWidget* widget, gpointer user_data) {
  if (g_windows_by_view_id != nullptr) {
    g_hash_table_remove(g_windows_by_view_id, user_data);
  }
}

static GtkWindow* resolve_target_window(GtkWindow* default_window,
                                        FlValue* args) {
  if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP &&
      g_windows_by_view_id != nullptr) {
    FlValue* v = fl_value_lookup_string(args, "viewId");
    if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
      gint view_id = static_cast<gint>(fl_value_get_int(v));
      gpointer found =
          g_hash_table_lookup(g_windows_by_view_id, GINT_TO_POINTER(view_id));
      if (found != nullptr) {
        return GTK_WINDOW(found);
      }
    }
  }
  return default_window;
}

static gboolean is_gdk_window_tiled(GtkWindow* window) {
  GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win == nullptr) return FALSE;
  GdkWindowState state = gdk_window_get_state(gdk_win);
  return (state & (GDK_WINDOW_STATE_TILED |
                   GDK_WINDOW_STATE_TOP_TILED |
                   GDK_WINDOW_STATE_RIGHT_TILED |
                   GDK_WINDOW_STATE_BOTTOM_TILED |
                   GDK_WINDOW_STATE_LEFT_TILED |
                   GDK_WINDOW_STATE_FULLSCREEN)) != 0;
}

static gboolean on_window_state_changed(GtkWidget* widget,
                                        GdkEventWindowState* event,
                                        gpointer user_data) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  if (channel == nullptr || event == nullptr) return FALSE;
  gint view_id = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(widget), "libadwaitter-view-id"));
  GdkWindowState state = event->new_window_state;
  gboolean is_max = (state & GDK_WINDOW_STATE_MAXIMIZED) != 0;
  gboolean is_tiled =
      (state & (GDK_WINDOW_STATE_TILED |
                GDK_WINDOW_STATE_TOP_TILED |
                GDK_WINDOW_STATE_RIGHT_TILED |
                GDK_WINDOW_STATE_BOTTOM_TILED |
                GDK_WINDOW_STATE_LEFT_TILED |
                GDK_WINDOW_STATE_FULLSCREEN)) != 0;
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
  fl_value_set_string_take(args, "isMaximized", fl_value_new_bool(is_max));
  fl_value_set_string_take(args, "isTiled", fl_value_new_bool(is_tiled));
  fl_method_channel_invoke_method(channel, "onWindowStateChanged", args,
                                  nullptr, nullptr, nullptr);
  return FALSE;
}

static void on_window_active_changed(GObject* object, GParamSpec* pspec, gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(object);
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
  gint view_id = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
  gboolean active = gtk_window_is_active(window);
  gboolean is_dragging =
      GPOINTER_TO_INT(g_object_get_data(G_OBJECT(window), "libadwaitter-interactive-drag")) != 0;

  if (active) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag", GINT_TO_POINTER(0));
  } else if (is_dragging) {
    // Compositor grabs (Wayland/X11 move or resize drag) transiently unset is-active;
    // keep the window visually focused just like native GTK4/Libadwaita windows.
    return;
  }

  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
  fl_value_set_string_take(args, "isActive", fl_value_new_bool(active));
  fl_method_channel_invoke_method(channel, "onWindowActiveChanged", args, nullptr, nullptr, nullptr);
}

static gboolean on_window_post_drag_event(GtkWidget* widget, GdkEvent* event, gpointer user_data) {
  gboolean is_dragging =
      GPOINTER_TO_INT(g_object_get_data(G_OBJECT(widget), "libadwaitter-interactive-drag")) != 0;
  if (is_dragging) {
    g_object_set_data(G_OBJECT(widget), "libadwaitter-interactive-drag", GINT_TO_POINTER(0));
    GtkWindow* window = GTK_WINDOW(widget);
    FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
    gint view_id = GPOINTER_TO_INT(
        g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
    gboolean active = gtk_window_is_active(window);
    if (!active) {
      g_autoptr(FlValue) args = fl_value_new_map();
      fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
      fl_value_set_string_take(args, "isActive", fl_value_new_bool(FALSE));
      fl_method_channel_invoke_method(channel, "onWindowActiveChanged", args, nullptr, nullptr, nullptr);
    }
  }
  return FALSE;
}

typedef struct {
  GdkDevice* device;
  gint button;
  gdouble x;
  gdouble y;
  gdouble root_x;
  gdouble root_y;
  guint32 timestamp;
} LastPointerState;

static gboolean on_capture_pointer_event(GtkWidget* widget,
                                         GdkEvent* event,
                                         gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  if (window == nullptr || event == nullptr) return FALSE;
  LastPointerState* state = static_cast<LastPointerState*>(
      g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
  if (state == nullptr) {
    state = g_new0(LastPointerState, 1);
    g_object_set_data_full(G_OBJECT(window), "libadwaitter-last-pointer", state,
                           g_free);
  }
  GdkDevice* dev = gdk_event_get_device(event);
  if (dev != nullptr) {
    state->device = dev;
  }
  gdouble wx = 0, wy = 0;
  if (gdk_event_get_coords(event, &wx, &wy)) {
    state->x = wx;
    state->y = wy;
  }
  gdouble rx = 0, ry = 0;
  if (gdk_event_get_root_coords(event, &rx, &ry)) {
    state->root_x = rx;
    state->root_y = ry;
  }
  guint32 ts = gdk_event_get_time(event);
  if (ts != GDK_CURRENT_TIME) {
    state->timestamp = ts;
  }
  guint btn = 0;
  if (gdk_event_get_button(event, &btn) && btn > 0) {
    state->button = static_cast<gint>(btn);
  } else if (state->button == 0) {
    state->button = 1;
  }
  return FALSE;
}

static void release_fl_view_pointer_state(GtkWindow* window,
                                          LastPointerState* state) {
  GtkWidget* view_widget = GTK_WIDGET(
      g_object_get_data(G_OBJECT(window), "libadwaitter-fl-view"));
  if (view_widget == nullptr) return;
  GdkWindow* view_gdk_win = gtk_widget_get_window(view_widget);
  if (view_gdk_win == nullptr) return;

  GdkEvent* rel = gdk_event_new(GDK_BUTTON_RELEASE);
  rel->button.window = GDK_WINDOW(g_object_ref(view_gdk_win));
  rel->button.send_event = TRUE;
  rel->button.time = state != nullptr ? state->timestamp : GDK_CURRENT_TIME;
  rel->button.x = state != nullptr ? state->x : 0.0;
  rel->button.y = state != nullptr ? state->y : 0.0;
  rel->button.x_root = state != nullptr ? state->root_x : 0.0;
  rel->button.y_root = state != nullptr ? state->root_y : 0.0;
  rel->button.button =
      (state != nullptr && state->button > 0) ? state->button : 1;
  rel->button.state = GDK_BUTTON1_MASK;
  if (state != nullptr && state->device != nullptr) {
    gdk_event_set_device(rel, state->device);
  }
  gtk_widget_event(view_widget, rel);
  gdk_event_free(rel);
}

static void window_method_call_handler(FlMethodChannel* channel,
                                       FlMethodCall* method_call,
                                       gpointer user_data) {
  GtkWindow* default_window = GTK_WINDOW(user_data);
  FlValue* call_args = fl_method_call_get_args(method_call);
  GtkWindow* window = resolve_target_window(default_window, call_args);
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "attachSubWindow") == 0) {
    if (call_args != nullptr &&
        fl_value_get_type(call_args) == FL_VALUE_TYPE_MAP) {
      FlValue* win_val = fl_value_lookup_string(call_args, "windowHandle");
      FlValue* view_val = fl_value_lookup_string(call_args, "viewHandle");
      FlValue* id_val = fl_value_lookup_string(call_args, "viewId");
      if (win_val != nullptr && view_val != nullptr && id_val != nullptr) {
        GtkWindow* sub_win = GTK_WINDOW(
            reinterpret_cast<gpointer>(fl_value_get_int(win_val)));
        FlView* sub_view = FL_VIEW(
            reinterpret_cast<gpointer>(fl_value_get_int(view_val)));
        gint view_id = static_cast<gint>(fl_value_get_int(id_val));
        if (g_windows_by_view_id == nullptr) {
          g_windows_by_view_id =
              g_hash_table_new(g_direct_hash, g_direct_equal);
        }
        g_hash_table_insert(g_windows_by_view_id, GINT_TO_POINTER(view_id),
                            sub_win);
        FlValue* parent_val = fl_value_lookup_string(call_args, "parentViewId");
        if (parent_val != nullptr &&
            fl_value_get_type(parent_val) == FL_VALUE_TYPE_INT) {
          gint parent_view_id =
              static_cast<gint>(fl_value_get_int(parent_val));
          GtkWindow* parent_win = GTK_WINDOW(g_hash_table_lookup(
              g_windows_by_view_id, GINT_TO_POINTER(parent_view_id)));
          if (parent_win != nullptr && parent_win != sub_win) {
            gtk_window_set_transient_for(sub_win, parent_win);
          }
        }
        g_object_set_data(G_OBJECT(sub_win), "libadwaitter-view-id",
                          GINT_TO_POINTER(view_id));
        g_object_set_data(G_OBJECT(sub_win), "libadwaitter-fl-view", sub_view);
        g_signal_connect(sub_win, "destroy",
                         G_CALLBACK(on_sub_window_destroyed),
                         GINT_TO_POINTER(view_id));
        g_signal_connect(sub_win, "draw", G_CALLBACK(window_draw_cb), nullptr);
        g_signal_connect(sub_win, "notify::is-active",
                         G_CALLBACK(on_window_active_changed), channel);
        g_signal_connect(sub_win, "window-state-event",
                         G_CALLBACK(on_window_state_changed), channel);
        gtk_widget_add_events(
            GTK_WIDGET(sub_win),
            GDK_ENTER_NOTIFY_MASK | GDK_BUTTON_RELEASE_MASK);
        g_signal_connect(sub_view, "button-press-event",
                         G_CALLBACK(on_capture_pointer_event), sub_win);
        g_signal_connect(sub_view, "motion-notify-event",
                         G_CALLBACK(on_capture_pointer_event), sub_win);
        g_signal_connect(sub_win, "enter-notify-event",
                         G_CALLBACK(on_window_post_drag_event), channel);
        g_signal_connect(sub_win, "button-release-event",
                         G_CALLBACK(on_window_post_drag_event), channel);
      }
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "startDragging") == 0) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag", GINT_TO_POINTER(1));
    LastPointerState* state = static_cast<LastPointerState*>(
        g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
    release_fl_view_pointer_state(window, state);
    if (state != nullptr && state->timestamp != GDK_CURRENT_TIME) {
      gtk_window_begin_move_drag(
          window, state->button > 0 ? state->button : 1,
          static_cast<gint>(state->root_x), static_cast<gint>(state->root_y),
          state->timestamp);
    } else {
      GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
      GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
      gint x = 0, y = 0;
      if (pointer != nullptr) {
        gdk_device_get_position(pointer, nullptr, &x, &y);
      }
      guint32 timestamp = gtk_get_current_event_time();
      gtk_window_begin_move_drag(window, 1, x, y, timestamp);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "beginResizeDrag") == 0) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag", GINT_TO_POINTER(1));
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* edge_str = "bottomRight";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* val = fl_value_lookup_string(args, "edge");
      if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING) {
        edge_str = fl_value_get_string(val);
      }
    } else if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_STRING) {
      edge_str = fl_value_get_string(args);
    }

    GdkWindowEdge edge = GDK_WINDOW_EDGE_SOUTH_EAST;
    if (strcmp(edge_str, "top") == 0) {
      edge = GDK_WINDOW_EDGE_NORTH;
    } else if (strcmp(edge_str, "bottom") == 0) {
      edge = GDK_WINDOW_EDGE_SOUTH;
    } else if (strcmp(edge_str, "left") == 0) {
      edge = GDK_WINDOW_EDGE_WEST;
    } else if (strcmp(edge_str, "right") == 0) {
      edge = GDK_WINDOW_EDGE_EAST;
    } else if (strcmp(edge_str, "topLeft") == 0) {
      edge = GDK_WINDOW_EDGE_NORTH_WEST;
    } else if (strcmp(edge_str, "topRight") == 0) {
      edge = GDK_WINDOW_EDGE_NORTH_EAST;
    } else if (strcmp(edge_str, "bottomLeft") == 0) {
      edge = GDK_WINDOW_EDGE_SOUTH_WEST;
    } else if (strcmp(edge_str, "bottomRight") == 0) {
      edge = GDK_WINDOW_EDGE_SOUTH_EAST;
    }

    LastPointerState* state = static_cast<LastPointerState*>(
        g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
    release_fl_view_pointer_state(window, state);
    if (state != nullptr && state->timestamp != GDK_CURRENT_TIME) {
      gtk_window_begin_resize_drag(
          window, edge, state->button > 0 ? state->button : 1,
          static_cast<gint>(state->root_x), static_cast<gint>(state->root_y),
          state->timestamp);
    } else {
      GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
      GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
      gint x = 0, y = 0;
      if (pointer != nullptr) {
        gdk_device_get_position(pointer, nullptr, &x, &y);
      }
      guint32 timestamp = gtk_get_current_event_time();
      gtk_window_begin_resize_drag(window, edge, 1, x, y, timestamp);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "close") == 0) {
    gtk_window_close(window);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "minimize") == 0) {
    gtk_window_iconify(window);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "maximize") == 0) {
    if (gtk_window_is_maximized(window)) {
      gtk_window_unmaximize(window);
    } else {
      gtk_window_maximize(window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "isMaximized") == 0) {
    gboolean is_max = gtk_window_is_maximized(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_max);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "setFullscreen") == 0) {
    gboolean fullscreen = FALSE;
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* val = fl_value_lookup_string(args, "fullscreen");
      if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_BOOL) {
        fullscreen = fl_value_get_bool(val);
      }
    }
    if (fullscreen) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "isFullscreen") == 0) {
    GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
    gboolean is_full = gdk_win != nullptr &&
        (gdk_window_get_state(gdk_win) & GDK_WINDOW_STATE_FULLSCREEN) != 0;
    g_autoptr(FlValue) result = fl_value_new_bool(is_full);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "isTiled") == 0) {
    gboolean is_tiled = is_gdk_window_tiled(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_tiled);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "isActive") == 0) {
    gboolean is_act = gtk_window_is_active(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_act);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "getWindowHandles") == 0) {
    FlView* view_widget = FL_VIEW(
        g_object_get_data(G_OBJECT(window), "libadwaitter-fl-view"));
    gint view_id = GPOINTER_TO_INT(
        g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(
        map, "windowHandle",
        fl_value_new_int(reinterpret_cast<int64_t>(window)));
    fl_value_set_string_take(
        map, "viewHandle",
        fl_value_new_int(reinterpret_cast<int64_t>(view_widget)));
    fl_value_set_string_take(map, "viewId", fl_value_new_int(view_id));
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "attachPopupWindow") == 0) {
    if (call_args != nullptr &&
        fl_value_get_type(call_args) == FL_VALUE_TYPE_MAP) {
      FlValue* win_val = fl_value_lookup_string(call_args, "windowHandle");
      if (win_val != nullptr) {
        GtkWindow* popup_win = GTK_WINDOW(
            reinterpret_cast<gpointer>(fl_value_get_int(win_val)));
        if (popup_win != nullptr) {
          g_signal_connect(popup_win, "draw", G_CALLBACK(window_draw_cb),
                           nullptr);
        }
      }
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

// --- XDG Desktop Portal & Linux Sandbox Bridge (libadwaitter/portal) ---

static FlValue* build_portal_result(const char* status,
                                    FlValue* value_take,
                                    const char* error_message) {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "status", fl_value_new_string(status));
  if (value_take != nullptr) {
    fl_value_set_string_take(map, "value", value_take);
  }
  if (error_message != nullptr) {
    fl_value_set_string_take(map, "errorMessage",
                             fl_value_new_string(error_message));
  }
  return map;
}

typedef struct {
  FlMethodCall* method_call;
  GDBusConnection* connection;
  guint signal_id;
  bool return_screenshot_uri;
} PortalAsyncRequest;

static void portal_async_request_free(PortalAsyncRequest* req) {
  if (req == nullptr) return;
  if (req->signal_id != 0 && req->connection != nullptr) {
    g_dbus_connection_signal_unsubscribe(req->connection, req->signal_id);
    req->signal_id = 0;
  }
  if (req->connection != nullptr) {
    g_object_unref(req->connection);
  }
  if (req->method_call != nullptr) {
    g_object_unref(req->method_call);
  }
  g_free(req);
}

static void on_portal_request_response(GDBusConnection* connection,
                                       const gchar* sender_name,
                                       const gchar* object_path,
                                       const gchar* interface_name,
                                       const gchar* signal_name,
                                       GVariant* parameters,
                                       gpointer user_data) {
  PortalAsyncRequest* req = static_cast<PortalAsyncRequest*>(user_data);
  if (req == nullptr || req->method_call == nullptr) return;

  guint32 response_code = 2;
  g_autoptr(GVariant) results = nullptr;
  g_variant_get(parameters, "(u@a{sv})", &response_code, &results);

  g_autoptr(FlValue) reply = nullptr;
  if (response_code == 0) {
    if (req->return_screenshot_uri && results != nullptr) {
      const gchar* uri = nullptr;
      if (g_variant_lookup(results, "uri", "&s", &uri) && uri != nullptr) {
        reply = build_portal_result("granted", fl_value_new_string(uri), nullptr);
      } else {
        reply = build_portal_result("granted", nullptr, nullptr);
      }
    } else {
      reply = build_portal_result("granted", fl_value_new_bool(TRUE), nullptr);
    }
  } else if (response_code == 1) {
    reply = build_portal_result("cancelled", nullptr, nullptr);
  } else {
    reply = build_portal_result("denied", nullptr,
                                "Permission denied by user or portal.");
  }

  fl_method_call_respond_success(req->method_call, reply, nullptr);
  portal_async_request_free(req);
}

static void on_portal_dbus_call_finished(GObject* source_object,
                                         GAsyncResult* res,
                                         gpointer user_data) {
  PortalAsyncRequest* req = static_cast<PortalAsyncRequest*>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_finish(
      G_DBUS_CONNECTION(source_object), res, &error);
  if (error != nullptr) {
    g_autoptr(FlValue) reply =
        build_portal_result("unsupported", nullptr, error->message);
    fl_method_call_respond_success(req->method_call, reply, nullptr);
    portal_async_request_free(req);
    return;
  }
  // Response will arrive via org.freedesktop.portal.Request::Response signal.
  (void)result;
}

static void dispatch_portal_request(FlMethodCall* method_call,
                                    const char* interface_name,
                                    const char* method_name,
                                    GVariant* parameters,
                                    const char* expected_request_path,
                                    GDBusConnection* bus,
                                    bool return_screenshot_uri) {
  PortalAsyncRequest* req = g_new0(PortalAsyncRequest, 1);
  req->method_call = FL_METHOD_CALL(g_object_ref(method_call));
  req->connection = G_DBUS_CONNECTION(g_object_ref(bus));
  req->return_screenshot_uri = return_screenshot_uri;

  req->signal_id = g_dbus_connection_signal_subscribe(
      bus, "org.freedesktop.portal.Desktop", "org.freedesktop.portal.Request",
      "Response", expected_request_path, nullptr, G_DBUS_SIGNAL_FLAGS_NO_MATCH_RULE,
      on_portal_request_response, req, nullptr);

  g_dbus_connection_call(
      bus, "org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
      interface_name, method_name, parameters, G_VARIANT_TYPE("(o)"),
      G_DBUS_CALL_FLAGS_NONE, -1, nullptr, on_portal_dbus_call_finished, req);
}

static gchar* build_portal_request_path(GDBusConnection* bus,
                                        const char* token) {
  const gchar* unique_name = g_dbus_connection_get_unique_name(bus);
  g_autofree gchar* sanitized = g_strdup(unique_name != nullptr ? unique_name : "");
  if (sanitized[0] == ':') {
    sanitized[0] = '_';
    for (gchar* p = sanitized + 1; *p != '\0'; ++p) {
      if (*p == '.') *p = '_';
    }
  }
  return g_strdup_printf("/org/freedesktop/portal/desktop/request/%s/%s",
                         sanitized[0] == '_' ? sanitized + 1 : sanitized, token);
}

static void portal_method_call_handler(FlMethodChannel* channel,
                                       FlMethodCall* method_call,
                                       gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getSandboxInfo") == 0) {
    gboolean is_flatpak = g_file_test("/.flatpak-info", G_FILE_TEST_EXISTS);
    const gchar* flatpak_id = g_getenv("FLATPAK_ID");
    const gchar* snap_dir = g_getenv("SNAP");
    const gchar* snap_name = g_getenv("SNAP_NAME");
    const gchar* wayland_display = g_getenv("WAYLAND_DISPLAY");

    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(map, "isFlatpak",
                             fl_value_new_bool(is_flatpak || flatpak_id != nullptr));
    fl_value_set_string_take(map, "isSnap",
                             fl_value_new_bool(snap_dir != nullptr || snap_name != nullptr));
    fl_value_set_string_take(map, "isWayland",
                             fl_value_new_bool(wayland_display != nullptr && wayland_display[0] != '\0'));
    if (flatpak_id != nullptr) {
      fl_value_set_string_take(map, "flatpakId", fl_value_new_string(flatpak_id));
    }
    if (snap_name != nullptr) {
      fl_value_set_string_take(map, "snapName", fl_value_new_string(snap_name));
    }
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "openUri") == 0) {
    const gchar* uri = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* uri_val = fl_value_lookup_string(args, "uri");
      if (uri_val != nullptr && fl_value_get_type(uri_val) == FL_VALUE_TYPE_STRING) {
        uri = fl_value_get_string(uri_val);
      }
    }
    if (uri == nullptr) {
      g_autoptr(FlValue) reply = build_portal_result("error", nullptr, "Missing uri argument.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    g_autoptr(GError) error = nullptr;
    if (gtk_show_uri_on_window(window, uri, GDK_CURRENT_TIME, &error)) {
      g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
      fl_method_call_respond_success(method_call, reply, nullptr);
    } else {
      g_autoptr(FlValue) reply = build_portal_result(
          "error", nullptr, error != nullptr ? error->message : "Failed to open URI.");
      fl_method_call_respond_success(method_call, reply, nullptr);
    }
  } else if (strcmp(method, "sendNotification") == 0) {
    const gchar* id = "default";
    const gchar* title = "";
    const gchar* body = nullptr;
    const gchar* icon_name = nullptr;
    const gchar* priority_str = "normal";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "id")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        id = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "title")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "body")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        body = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "iconName")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        icon_name = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "priority")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        priority_str = fl_value_get_string(v);
    }
    g_autoptr(GNotification) notification = g_notification_new(title);
    if (body != nullptr) g_notification_set_body(notification, body);
    if (icon_name != nullptr) {
      g_autoptr(GIcon) icon = g_themed_icon_new(icon_name);
      g_notification_set_icon(notification, icon);
    }
    if (strcmp(priority_str, "low") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_LOW);
    } else if (strcmp(priority_str, "high") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_HIGH);
    } else if (strcmp(priority_str, "urgent") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_URGENT);
    } else {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_NORMAL);
    }
    g_application_send_notification(g_application_get_default(), id, notification);
    g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "withdrawNotification") == 0) {
    const gchar* id = "default";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = fl_value_lookup_string(args, "id");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        id = fl_value_get_string(v);
      }
    }
    g_application_withdraw_notification(g_application_get_default(), id);
    g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "openFiles") == 0) {
    const gchar* title = "Open File";
    gboolean multiple = FALSE;
    gboolean directory = FALSE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "title")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "multiple")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        multiple = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "directory")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        directory = fl_value_get_bool(v);
    }
    GtkFileChooserAction action = directory
        ? GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER
        : GTK_FILE_CHOOSER_ACTION_OPEN;
    GtkFileChooserNative* chooser = gtk_file_chooser_native_new(
        title, window, action, "_Open", "_Cancel");
    gtk_file_chooser_set_select_multiple(GTK_FILE_CHOOSER(chooser), multiple);
    gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(chooser));
    g_autoptr(FlValue) reply = nullptr;
    if (res == GTK_RESPONSE_ACCEPT) {
      FlValue* list = fl_value_new_list();
      GSList* files = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(chooser));
      for (GSList* iter = files; iter != nullptr; iter = iter->next) {
        gchar* path = static_cast<gchar*>(iter->data);
        fl_value_append_take(list, fl_value_new_string(path));
        g_free(path);
      }
      g_slist_free(files);
      reply = build_portal_result("granted", list, nullptr);
    } else {
      reply = build_portal_result("cancelled", nullptr, nullptr);
    }
    g_object_unref(chooser);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "saveFile") == 0) {
    const gchar* title = "Save File";
    const gchar* current_name = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "title")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "currentName")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        current_name = fl_value_get_string(v);
    }
    GtkFileChooserNative* chooser = gtk_file_chooser_native_new(
        title, window, GTK_FILE_CHOOSER_ACTION_SAVE, "_Save", "_Cancel");
    gtk_file_chooser_set_do_overwrite_confirmation(GTK_FILE_CHOOSER(chooser), TRUE);
    if (current_name != nullptr) {
      gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(chooser), current_name);
    }
    gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(chooser));
    g_autoptr(FlValue) reply = nullptr;
    if (res == GTK_RESPONSE_ACCEPT) {
      g_autofree gchar* path = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(chooser));
      reply = build_portal_result(
          "granted", path != nullptr ? fl_value_new_string(path) : nullptr, nullptr);
    } else {
      reply = build_portal_result("cancelled", nullptr, nullptr);
    }
    g_object_unref(chooser);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "inhibit") == 0) {
    const gchar* reason = "Application activity";
    gboolean idle = TRUE;
    gboolean suspend = FALSE;
    gboolean logout = FALSE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = nullptr;
      if ((v = fl_value_lookup_string(args, "reason")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        reason = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "idle")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        idle = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "suspend")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        suspend = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "logout")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        logout = fl_value_get_bool(v);
    }
    int flags = 0;
    if (logout) flags |= GTK_APPLICATION_INHIBIT_LOGOUT;
    if (suspend) flags |= GTK_APPLICATION_INHIBIT_SUSPEND;
    if (idle) flags |= GTK_APPLICATION_INHIBIT_IDLE;
    guint cookie = gtk_application_inhibit(
        GTK_APPLICATION(g_application_get_default()), window,
        static_cast<GtkApplicationInhibitFlags>(flags), reason);
    g_autoptr(FlValue) reply = nullptr;
    if (cookie != 0) {
      g_autofree gchar* handle = g_strdup_printf("%u", cookie);
      reply = build_portal_result("granted", fl_value_new_string(handle), nullptr);
    } else {
      reply = build_portal_result("unsupported", nullptr,
                                  "Session inhibit not supported by desktop.");
    }
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "uninhibit") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* v = fl_value_lookup_string(args, "handle");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        guint cookie = static_cast<guint>(g_ascii_strtoull(fl_value_get_string(v), nullptr, 10));
        if (cookie != 0) {
          gtk_application_uninhibit(GTK_APPLICATION(g_application_get_default()), cookie);
        }
      }
    }
    g_autoptr(FlValue) reply = build_portal_result("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "requestBackground") == 0 ||
             strcmp(method, "requestCamera") == 0 ||
             strcmp(method, "takeScreenshot") == 0) {
    g_autoptr(GError) bus_error = nullptr;
    g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &bus_error);
    if (bus == nullptr) {
      g_autoptr(FlValue) reply = build_portal_result(
          "error", nullptr, bus_error != nullptr ? bus_error->message : "No session D-Bus.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }

    g_autofree gchar* token = g_strdup_printf("libadwaitter_%u", g_random_int());
    g_autofree gchar* request_path = build_portal_request_path(bus, token);

    GVariantBuilder options;
    g_variant_builder_init(&options, G_VARIANT_TYPE_VARDICT);
    g_variant_builder_add(&options, "{sv}", "handle_token", g_variant_new_string(token));

    if (strcmp(method, "requestBackground") == 0) {
      const gchar* reason = "Allow running in background";
      gboolean autostart = FALSE;
      if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
        FlValue* v = nullptr;
        if ((v = fl_value_lookup_string(args, "reason")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
          reason = fl_value_get_string(v);
        if ((v = fl_value_lookup_string(args, "autostart")) != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
          autostart = fl_value_get_bool(v);
      }
      g_variant_builder_add(&options, "{sv}", "reason", g_variant_new_string(reason));
      g_variant_builder_add(&options, "{sv}", "autostart", g_variant_new_boolean(autostart));
      dispatch_portal_request(
          method_call, "org.freedesktop.portal.Background", "RequestBackground",
          g_variant_new("(sa{sv})", "", &options), request_path, bus, false);
    } else if (strcmp(method, "requestCamera") == 0) {
      dispatch_portal_request(
          method_call, "org.freedesktop.portal.Camera", "AccessCamera",
          g_variant_new("(a{sv})", &options), request_path, bus, false);
    } else {
      gboolean interactive = TRUE;
      if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
        FlValue* v = fl_value_lookup_string(args, "interactive");
        if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
          interactive = fl_value_get_bool(v);
      }
      g_variant_builder_add(&options, "{sv}", "interactive", g_variant_new_boolean(interactive));
      dispatch_portal_request(
          method_call, "org.freedesktop.portal.Screenshot", "Screenshot",
          g_variant_new("(sa{sv})", "", &options), request_path, bus, true);
    }
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

// Cairo draw callback ensuring true alpha transparency (preventing opaque corner artifacts)
static gboolean window_draw_cb(GtkWidget* widget, cairo_t* cr, gpointer user_data) {
  cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
  cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint(cr);
  return FALSE;
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  g_setenv("GTK_USE_PORTAL", "1", FALSE);
  MyApplication* self = MY_APPLICATION(application);

  // Set Wayland xdg_toplevel app_id / prgname so compositors match .desktop & icon
  g_set_prgname(APPLICATION_ID);
  g_set_application_name("Adwaitter Demo");

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  gtk_window_set_default_size(window, 1080, 720);

  // Enforce Libadwaita's standard minimum window dimensions (360x294)
  GdkGeometry min_geometry = {};
  min_geometry.min_width = 360;
  min_geometry.min_height = 294;
  gtk_window_set_geometry_hints(window, nullptr, &min_geometry,
                                GDK_HINT_MIN_SIZE);

  // Configure RGBA visual for alpha transparency and rounded corners
  GdkScreen* screen = gtk_window_get_screen(window);
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr && gdk_screen_is_composited(screen)) {
    gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);
    gtk_widget_set_visual(GTK_WIDGET(window), visual);
  }

  // Hook draw signal to clear the Cairo surface to transparent black (operator CLEAR)
  g_signal_connect(window, "draw", G_CALLBACK(window_draw_cb), nullptr);

  // Apply transparent GTK CSS rule preventing opaque background drawing
  GtkCssProvider* css_provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(
      css_provider,
      "window, .background, decoration { background-color: transparent !important; background: transparent !important; border: none !important; box-shadow: none !important; }",
      -1, nullptr);
  gtk_style_context_add_provider_for_screen(
      screen, GTK_STYLE_PROVIDER(css_provider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  // Disable server-side decorations (SSD) to enable in-app client-side decorations (CSD)
  gtk_window_set_decorated(window, FALSE);

  gtk_window_set_title(window, "Adwaitter Demo");

  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path != nullptr) {
    g_autofree gchar* exe_dir = g_path_get_dirname(exe_path);
    g_autofree gchar* icon_path =
        g_build_filename(exe_dir, "data", "adwaitter_demo.png", nullptr);
    if (g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
      gtk_window_set_icon_from_file(window, icon_path, nullptr);
    }
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  // Configure FlView background as fully transparent (alpha = 0.0)
  GdkRGBA background_color = {0.0, 0.0, 0.0, 0.0};
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Register Libadwaitter window control MethodChannel
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* window_channel =
      fl_method_channel_new(messenger, kWindowChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      window_channel, window_method_call_handler, window, nullptr);
  g_signal_connect(window, "notify::is-active",
                   G_CALLBACK(on_window_active_changed), window_channel);
  g_signal_connect(window, "window-state-event",
                   G_CALLBACK(on_window_state_changed), window_channel);
  if (g_windows_by_view_id == nullptr) {
    g_windows_by_view_id = g_hash_table_new(g_direct_hash, g_direct_equal);
  }
  gint main_view_id = static_cast<gint>(fl_view_get_id(view));
  g_hash_table_insert(g_windows_by_view_id, GINT_TO_POINTER(0), window);
  g_hash_table_insert(g_windows_by_view_id, GINT_TO_POINTER(main_view_id),
                      window);
  g_object_set_data(G_OBJECT(window), "libadwaitter-view-id",
                    GINT_TO_POINTER(0));
  g_object_set_data(G_OBJECT(window), "libadwaitter-fl-view", view);
  gtk_widget_add_events(GTK_WIDGET(window),
                        GDK_ENTER_NOTIFY_MASK | GDK_BUTTON_RELEASE_MASK);
  g_signal_connect(view, "button-press-event",
                   G_CALLBACK(on_capture_pointer_event), window);
  g_signal_connect(view, "motion-notify-event",
                   G_CALLBACK(on_capture_pointer_event), window);
  g_signal_connect(window, "enter-notify-event",
                   G_CALLBACK(on_window_post_drag_event), window_channel);
  g_signal_connect(window, "button-release-event",
                   G_CALLBACK(on_window_post_drag_event), window_channel);

  // Register Libadwaitter desktop animation and system settings MethodChannel
  FlMethodChannel* settings_channel =
      fl_method_channel_new(messenger, kSettingsChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      settings_channel, settings_method_call_handler, settings_channel, nullptr);

  // Register Libadwaitter central style manager MethodChannel (theme & accent color)
  FlMethodChannel* style_channel =
      fl_method_channel_new(messenger, kStyleChannelName, FL_METHOD_CODEC(codec));
  StyleBridgeState* style_state = g_new0(StyleBridgeState, 1);
  style_state->channel = style_channel;
  g_object_set_data_full(G_OBJECT(window), "libadwaitter-style-bridge",
                         style_state, style_bridge_state_free);
  fl_method_channel_set_method_call_handler(
      style_channel, style_method_call_handler, style_state, nullptr);

  // Register Libadwaitter XDG Desktop Portal & sandbox bridge MethodChannel
  FlMethodChannel* portal_channel =
      fl_method_channel_new(messenger, kPortalChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      portal_channel, portal_method_call_handler, window, nullptr);

  GSettingsSchemaSource* schema_source = g_settings_schema_source_get_default();
  if (schema_source != nullptr) {
    g_autoptr(GSettingsSchema) interface_schema =
        g_settings_schema_source_lookup(schema_source, "org.gnome.desktop.interface", TRUE);
    if (interface_schema != nullptr) {
      style_state->interface_settings = g_settings_new("org.gnome.desktop.interface");
      if (g_settings_schema_has_key(interface_schema, "color-scheme")) {
        g_signal_connect(style_state->interface_settings, "changed::color-scheme",
                         G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings, "color-scheme"));
      } else if (g_settings_schema_has_key(interface_schema, "gtk-theme")) {
        g_signal_connect(style_state->interface_settings, "changed::gtk-theme",
                         G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings, "gtk-theme"));
      }
      if (g_settings_schema_has_key(interface_schema, "accent-color")) {
        g_signal_connect(style_state->interface_settings, "changed::accent-color",
                         G_CALLBACK(on_gsettings_appearance_changed), style_state);
        g_free(g_settings_get_string(style_state->interface_settings, "accent-color"));
      }
    }

    g_autoptr(GSettingsSchema) a11y_schema =
        g_settings_schema_source_lookup(schema_source, "org.gnome.desktop.a11y.interface", TRUE);
    if (a11y_schema != nullptr && g_settings_schema_has_key(a11y_schema, "high-contrast")) {
      style_state->a11y_settings = g_settings_new("org.gnome.desktop.a11y.interface");
      g_signal_connect(style_state->a11y_settings, "changed::high-contrast",
                       G_CALLBACK(on_gsettings_appearance_changed), style_state);
      (void)g_settings_get_boolean(style_state->a11y_settings, "high-contrast");
    }
    g_autoptr(GSettingsSchema) wm_schema =
        g_settings_schema_source_lookup(schema_source, "org.gnome.desktop.wm.preferences", TRUE);
    if (wm_schema != nullptr && g_settings_schema_has_key(wm_schema, "button-layout")) {
      GSettings* wm_settings = g_settings_new("org.gnome.desktop.wm.preferences");
      g_object_set_data_full(G_OBJECT(window), "libadwaitter-wm-gsettings",
                             wm_settings, g_object_unref);
      g_signal_connect(wm_settings, "changed::button-layout",
                       G_CALLBACK(on_wm_button_layout_changed), settings_channel);
      g_free(g_settings_get_string(wm_settings, "button-layout"));
    }
  }

  GWeakRef* weak_window = g_new(GWeakRef, 1);
  g_weak_ref_init(weak_window, window);
  g_bus_get(G_BUS_TYPE_SESSION, nullptr, on_session_bus_ready, weak_window);

  GtkSettings* default_settings = gtk_settings_get_default();
  if (default_settings != nullptr) {
    g_signal_connect(default_settings, "notify::gtk-enable-animations",
                     G_CALLBACK(on_gtk_animations_changed), settings_channel);
    g_signal_connect(default_settings, "notify::gtk-decoration-layout",
                     G_CALLBACK(on_gtk_decoration_layout_changed), settings_channel);
  }

  // Show the window when Flutter renders.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_init(MyApplication* self) {}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
