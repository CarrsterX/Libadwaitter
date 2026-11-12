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

static void on_window_active_changed(GObject* object, GParamSpec* pspec, gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(object);
  FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
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

  g_autoptr(FlValue) val = fl_value_new_bool(active);
  fl_method_channel_invoke_method(channel, "onWindowActiveChanged", val, nullptr, nullptr, nullptr);
}

static gboolean on_window_post_drag_event(GtkWidget* widget, GdkEvent* event, gpointer user_data) {
  gboolean is_dragging =
      GPOINTER_TO_INT(g_object_get_data(G_OBJECT(widget), "libadwaitter-interactive-drag")) != 0;
  if (is_dragging) {
    g_object_set_data(G_OBJECT(widget), "libadwaitter-interactive-drag", GINT_TO_POINTER(0));
    GtkWindow* window = GTK_WINDOW(widget);
    FlMethodChannel* channel = FL_METHOD_CHANNEL(user_data);
    gboolean active = gtk_window_is_active(window);
    if (!active) {
      g_autoptr(FlValue) val = fl_value_new_bool(FALSE);
      fl_method_channel_invoke_method(channel, "onWindowActiveChanged", val, nullptr, nullptr, nullptr);
    }
  }
  return FALSE;
}

static void window_method_call_handler(FlMethodChannel* channel,
                                       FlMethodCall* method_call,
                                       gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "startDragging") == 0) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag", GINT_TO_POINTER(1));
    GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
    GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
    gint x = 0, y = 0;
    if (pointer != nullptr) {
      gdk_device_get_position(pointer, nullptr, &x, &y);
    }
    guint32 timestamp = gtk_get_current_event_time();
    // Initiate native window drag (Wayland and X11) with pointer device and coordinates
    gtk_window_begin_move_drag(window, 1, x, y, timestamp);
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

    GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
    GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
    gint x = 0, y = 0;
    if (pointer != nullptr) {
      gdk_device_get_position(pointer, nullptr, &x, &y);
    }
    guint32 timestamp = gtk_get_current_event_time();
    // Initiate native window resize (Wayland and X11) with pointer device and coordinates
    gtk_window_begin_resize_drag(window, edge, 1, x, y, timestamp);
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
  } else if (strcmp(method, "isActive") == 0) {
    gboolean is_act = gtk_window_is_active(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_act);
    fl_method_call_respond_success(method_call, result, nullptr);
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
  MyApplication* self = MY_APPLICATION(application);

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  gtk_window_set_default_size(window, 1080, 720);

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

  gtk_window_set_title(window, "Adwaita Demo");

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
  gtk_widget_add_events(GTK_WIDGET(window), GDK_ENTER_NOTIFY_MASK | GDK_BUTTON_RELEASE_MASK);
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
  }

  GWeakRef* weak_window = g_new(GWeakRef, 1);
  g_weak_ref_init(weak_window, window);
  g_bus_get(G_BUS_TYPE_SESSION, nullptr, on_session_bus_ready, weak_window);

  GtkSettings* default_settings = gtk_settings_get_default();
  if (default_settings != nullptr) {
    g_signal_connect(default_settings, "notify::gtk-enable-animations",
                     G_CALLBACK(on_gtk_animations_changed), settings_channel);
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
