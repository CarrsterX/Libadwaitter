#include "window/window_bridge.h"

#include <cstring>

namespace {

const char* kWindowChannelName = "libadwaitter/window";

static GHashTable *g_windows_by_view_id = nullptr;

static gboolean window_draw_cb(GtkWidget *widget, cairo_t *cr,
                               gpointer user_data);
static void apply_window_shadow_margin(GtkWindow *window, gint margin);
static void on_window_size_allocate(GtkWidget *widget,
                                    GtkAllocation *allocation,
                                    gpointer user_data);

static void on_sub_window_destroyed(GtkWidget *widget, gpointer user_data) {
  if (g_windows_by_view_id != nullptr) {
    g_hash_table_remove(g_windows_by_view_id, user_data);
  }
}

static GtkWindow *resolve_target_window(GtkWindow *default_window,
                                        FlValue *args) {
  if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP &&
      g_windows_by_view_id != nullptr) {
    FlValue *v = fl_value_lookup_string(args, "viewId");
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

static gboolean is_gdk_window_tiled(GtkWindow *window) {
  GdkWindow *gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win == nullptr)
    return FALSE;
  GdkWindowState state = gdk_window_get_state(gdk_win);
  return (state &
          (GDK_WINDOW_STATE_TILED | GDK_WINDOW_STATE_TOP_TILED |
           GDK_WINDOW_STATE_RIGHT_TILED | GDK_WINDOW_STATE_BOTTOM_TILED |
           GDK_WINDOW_STATE_LEFT_TILED | GDK_WINDOW_STATE_FULLSCREEN)) != 0;
}

static gboolean on_window_state_changed(GtkWidget *widget,
                                        GdkEventWindowState *event,
                                        gpointer user_data) {
  FlMethodChannel *channel = FL_METHOD_CHANNEL(user_data);
  if (channel == nullptr || event == nullptr)
    return FALSE;
  gint view_id = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(widget), "libadwaitter-view-id"));
  GdkWindowState state = event->new_window_state;
  gboolean is_max = (state & GDK_WINDOW_STATE_MAXIMIZED) != 0;
  gboolean is_tiled =
      (state & (GDK_WINDOW_STATE_TILED | GDK_WINDOW_STATE_TOP_TILED |
                GDK_WINDOW_STATE_RIGHT_TILED | GDK_WINDOW_STATE_BOTTOM_TILED |
                GDK_WINDOW_STATE_LEFT_TILED | GDK_WINDOW_STATE_FULLSCREEN)) !=
      0;
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
  fl_value_set_string_take(args, "isMaximized", fl_value_new_bool(is_max));
  fl_value_set_string_take(args, "isTiled", fl_value_new_bool(is_tiled));
  fl_method_channel_invoke_method(channel, "onWindowStateChanged", args,
                                  nullptr, nullptr, nullptr);
  return FALSE;
}

static void on_window_active_changed(GObject *object, GParamSpec *pspec,
                                     gpointer user_data) {
  GtkWindow *window = GTK_WINDOW(object);
  FlMethodChannel *channel = FL_METHOD_CHANNEL(user_data);
  gint view_id = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
  gboolean active = gtk_window_is_active(window);
  gboolean is_dragging =
      GPOINTER_TO_INT(g_object_get_data(G_OBJECT(window),
                                        "libadwaitter-interactive-drag")) != 0;

  if (active) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag",
                      GINT_TO_POINTER(0));
  } else if (is_dragging) {
    // Compositor grabs (Wayland/X11 move or resize drag) transiently unset
    // is-active; keep the window visually focused just like native
    // GTK4/Libadwaita windows.
    return;
  }

  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
  fl_value_set_string_take(args, "isActive", fl_value_new_bool(active));
  fl_method_channel_invoke_method(channel, "onWindowActiveChanged", args,
                                  nullptr, nullptr, nullptr);
}

static gboolean on_window_post_drag_event(GtkWidget *widget, GdkEvent *event,
                                          gpointer user_data) {
  gboolean is_dragging =
      GPOINTER_TO_INT(g_object_get_data(G_OBJECT(widget),
                                        "libadwaitter-interactive-drag")) != 0;
  if (is_dragging) {
    g_object_set_data(G_OBJECT(widget), "libadwaitter-interactive-drag",
                      GINT_TO_POINTER(0));
    GtkWindow *window = GTK_WINDOW(widget);
    FlMethodChannel *channel = FL_METHOD_CHANNEL(user_data);
    gint view_id = GPOINTER_TO_INT(
        g_object_get_data(G_OBJECT(window), "libadwaitter-view-id"));
    gboolean active = gtk_window_is_active(window);
    if (!active) {
      g_autoptr(FlValue) args = fl_value_new_map();
      fl_value_set_string_take(args, "viewId", fl_value_new_int(view_id));
      fl_value_set_string_take(args, "isActive", fl_value_new_bool(FALSE));
      fl_method_channel_invoke_method(channel, "onWindowActiveChanged", args,
                                      nullptr, nullptr, nullptr);
    }
  }
  return FALSE;
}

typedef struct {
  GdkDevice *device;
  gint button;
  gdouble x;
  gdouble y;
  gdouble root_x;
  gdouble root_y;
  guint32 timestamp;
} LastPointerState;

static gboolean on_capture_pointer_event(GtkWidget *widget, GdkEvent *event,
                                         gpointer user_data) {
  GtkWindow *window = GTK_WINDOW(user_data);
  if (window == nullptr || event == nullptr)
    return FALSE;
  LastPointerState *state = static_cast<LastPointerState *>(
      g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
  if (state == nullptr) {
    state = g_new0(LastPointerState, 1);
    g_object_set_data_full(G_OBJECT(window), "libadwaitter-last-pointer", state,
                           g_free);
  }
  GdkDevice *dev = gdk_event_get_device(event);
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

static void release_fl_view_pointer_state(GtkWindow *window,
                                          LastPointerState *state) {
  GtkWidget *view_widget =
      GTK_WIDGET(g_object_get_data(G_OBJECT(window), "libadwaitter-fl-view"));
  if (view_widget == nullptr)
    return;
  GdkWindow *view_gdk_win = gtk_widget_get_window(view_widget);
  if (view_gdk_win == nullptr)
    return;

  GdkEvent *rel = gdk_event_new(GDK_BUTTON_RELEASE);
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

static void window_method_call_handler(FlMethodChannel *channel,
                                       FlMethodCall *method_call,
                                       gpointer user_data) {
  GtkWindow *default_window = GTK_WINDOW(user_data);
  FlValue *call_args = fl_method_call_get_args(method_call);
  GtkWindow *window = resolve_target_window(default_window, call_args);
  const gchar *method = fl_method_call_get_name(method_call);

  if (strcmp(method, "attachSubWindow") == 0) {
    if (call_args != nullptr &&
        fl_value_get_type(call_args) == FL_VALUE_TYPE_MAP) {
      FlValue *win_val = fl_value_lookup_string(call_args, "windowHandle");
      FlValue *view_val = fl_value_lookup_string(call_args, "viewHandle");
      FlValue *id_val = fl_value_lookup_string(call_args, "viewId");
      if (win_val != nullptr && view_val != nullptr && id_val != nullptr) {
        GtkWindow *sub_win =
            GTK_WINDOW(reinterpret_cast<gpointer>(fl_value_get_int(win_val)));
        FlView *sub_view =
            FL_VIEW(reinterpret_cast<gpointer>(fl_value_get_int(view_val)));
        gint view_id = static_cast<gint>(fl_value_get_int(id_val));
        if (g_windows_by_view_id == nullptr) {
          g_windows_by_view_id =
              g_hash_table_new(g_direct_hash, g_direct_equal);
        }
        g_hash_table_insert(g_windows_by_view_id, GINT_TO_POINTER(view_id),
                            sub_win);
        FlValue *parent_val = fl_value_lookup_string(call_args, "parentViewId");
        if (parent_val != nullptr &&
            fl_value_get_type(parent_val) == FL_VALUE_TYPE_INT) {
          gint parent_view_id = static_cast<gint>(fl_value_get_int(parent_val));
          GtkWindow *parent_win = GTK_WINDOW(g_hash_table_lookup(
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
        g_signal_connect(sub_win, "size-allocate",
                         G_CALLBACK(on_window_size_allocate), nullptr);
        g_signal_connect(sub_win, "notify::is-active",
                         G_CALLBACK(on_window_active_changed), channel);
        g_signal_connect(sub_win, "window-state-event",
                         G_CALLBACK(on_window_state_changed), channel);
        gtk_widget_add_events(GTK_WIDGET(sub_win),
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
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag",
                      GINT_TO_POINTER(1));
    LastPointerState *state = static_cast<LastPointerState *>(
        g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
    release_fl_view_pointer_state(window, state);
    if (state != nullptr && state->timestamp != GDK_CURRENT_TIME) {
      gtk_window_begin_move_drag(window, state->button > 0 ? state->button : 1,
                                 static_cast<gint>(state->root_x),
                                 static_cast<gint>(state->root_y),
                                 state->timestamp);
    } else {
      GdkSeat *seat = gdk_display_get_default_seat(gdk_display_get_default());
      GdkDevice *pointer =
          seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
      gint x = 0, y = 0;
      if (pointer != nullptr) {
        gdk_device_get_position(pointer, nullptr, &x, &y);
      }
      guint32 timestamp = gtk_get_current_event_time();
      gtk_window_begin_move_drag(window, 1, x, y, timestamp);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "beginResizeDrag") == 0) {
    g_object_set_data(G_OBJECT(window), "libadwaitter-interactive-drag",
                      GINT_TO_POINTER(1));
    FlValue *args = fl_method_call_get_args(method_call);
    const gchar *edge_str = "bottomRight";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *val = fl_value_lookup_string(args, "edge");
      if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING) {
        edge_str = fl_value_get_string(val);
      }
    } else if (args != nullptr &&
               fl_value_get_type(args) == FL_VALUE_TYPE_STRING) {
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

    LastPointerState *state = static_cast<LastPointerState *>(
        g_object_get_data(G_OBJECT(window), "libadwaitter-last-pointer"));
    release_fl_view_pointer_state(window, state);
    if (state != nullptr && state->timestamp != GDK_CURRENT_TIME) {
      gtk_window_begin_resize_drag(
          window, edge, state->button > 0 ? state->button : 1,
          static_cast<gint>(state->root_x), static_cast<gint>(state->root_y),
          state->timestamp);
    } else {
      GdkSeat *seat = gdk_display_get_default_seat(gdk_display_get_default());
      GdkDevice *pointer =
          seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
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
    FlValue *args = fl_method_call_get_args(method_call);
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *val = fl_value_lookup_string(args, "fullscreen");
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
    GdkWindow *gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
    gboolean is_full = gdk_win != nullptr && (gdk_window_get_state(gdk_win) &
                                              GDK_WINDOW_STATE_FULLSCREEN) != 0;
    g_autoptr(FlValue) result = fl_value_new_bool(is_full);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "setShadowMargin") == 0) {
    gint margin = 0;
    FlValue *args = fl_method_call_get_args(method_call);
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *val = fl_value_lookup_string(args, "margin");
      if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_INT) {
        margin = static_cast<gint>(fl_value_get_int(val));
      }
    }
    apply_window_shadow_margin(window, margin);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "isTiled") == 0) {
    gboolean is_tiled = is_gdk_window_tiled(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_tiled);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "isActive") == 0) {
    gboolean is_act = gtk_window_is_active(window);
    g_autoptr(FlValue) result = fl_value_new_bool(is_act);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "getWindowHandles") == 0) {
    FlView *view_widget =
        FL_VIEW(g_object_get_data(G_OBJECT(window), "libadwaitter-fl-view"));
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
      FlValue *win_val = fl_value_lookup_string(call_args, "windowHandle");
      if (win_val != nullptr) {
        GtkWindow *popup_win =
            GTK_WINDOW(reinterpret_cast<gpointer>(fl_value_get_int(win_val)));
        if (popup_win != nullptr) {
          FlValue *accept_focus_val =
              fl_value_lookup_string(call_args, "acceptFocus");
          if (accept_focus_val != nullptr &&
              fl_value_get_type(accept_focus_val) == FL_VALUE_TYPE_BOOL &&
              !fl_value_get_bool(accept_focus_val)) {
            gtk_window_set_accept_focus(popup_win, FALSE);
            gtk_window_set_focus_on_map(popup_win, FALSE);
            gtk_widget_set_can_focus(GTK_WIDGET(popup_win), FALSE);
            GdkWindow *gdk_win = gtk_widget_get_window(GTK_WIDGET(popup_win));
            if (gdk_win != nullptr) {
              gdk_window_set_pass_through(gdk_win, TRUE);
            }
          }
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


static void apply_window_shadow_margin(GtkWindow *window, gint margin) {
  if (window == nullptr)
    return;
  g_object_set_data(G_OBJECT(window), "libadwaitter-shadow-margin",
                    GINT_TO_POINTER(margin));
  GdkWindow *gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win != nullptr) {
    gdk_window_set_shadow_width(gdk_win, margin, margin, margin, margin);
  }
}

static void on_window_size_allocate(GtkWidget *widget,
                                    GtkAllocation *allocation,
                                    gpointer user_data) {
  gint margin = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(widget), "libadwaitter-shadow-margin"));
  if (margin > 0) {
    apply_window_shadow_margin(GTK_WINDOW(widget), margin);
  }
}

// Cairo draw callback ensuring true alpha transparency (preventing opaque
// corner artifacts)
static gboolean window_draw_cb(GtkWidget *widget, cairo_t *cr,
                               gpointer user_data) {
  cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
  cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint(cr);
  return FALSE;
}


}  // namespace

namespace libadwaitter {

void ApplyWindowShadowMargin(GtkWindow* window, gint margin) {
  apply_window_shadow_margin(window, margin);
}

void RegisterWindowBridge(FlPluginRegistrar* registrar, FlView* view,
                          GtkWindow* window) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* window_channel = fl_method_channel_new(
      messenger, kWindowChannelName, FL_METHOD_CODEC(codec));
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
}

}  // namespace libadwaitter
