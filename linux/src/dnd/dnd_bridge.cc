#include "dnd/dnd_bridge.h"

namespace {

const char* kDndChannelName = "libadwaitter/dnd";

static FlMethodChannel *g_dnd_channel = nullptr;
static gboolean g_dnd_active = FALSE;

static const GtkTargetEntry kDropTargets[] = {
    {const_cast<gchar *>("text/uri-list"), 0, 1},
    {const_cast<gchar *>("text/plain;charset=utf-8"), 0, 2},
    {const_cast<gchar *>("UTF8_STRING"), 0, 2},
    {const_cast<gchar *>("text/plain"), 0, 2},
};

static gboolean on_view_drag_motion(GtkWidget *widget, GdkDragContext *context,
                                    gint x, gint y, guint time,
                                    gpointer user_data) {
  if (g_dnd_channel != nullptr) {
    const char *event_type = g_dnd_active ? "update" : "enter";
    g_dnd_active = TRUE;
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(map, "type", fl_value_new_string(event_type));
    fl_value_set_string_take(map, "x", fl_value_new_float(static_cast<double>(x)));
    fl_value_set_string_take(map, "y", fl_value_new_float(static_cast<double>(y)));
    fl_method_channel_invoke_method(g_dnd_channel, "onDropEvent", map, nullptr,
                                    nullptr, nullptr);
  }
  gdk_drag_status(context, GDK_ACTION_COPY, time);
  return TRUE;
}

static void on_view_drag_leave(GtkWidget *widget, GdkDragContext *context,
                               guint time, gpointer user_data) {
  g_dnd_active = FALSE;
  if (g_dnd_channel == nullptr)
    return;
  g_autoptr(FlValue) map = fl_value_new_map();
  fl_value_set_string_take(map, "type", fl_value_new_string("leave"));
  fl_method_channel_invoke_method(g_dnd_channel, "onDropEvent", map, nullptr,
                                  nullptr, nullptr);
}

static void on_view_drag_data_received(GtkWidget *widget,
                                       GdkDragContext *context, gint x, gint y,
                                       GtkSelectionData *selection_data,
                                       guint info, guint time,
                                       gpointer user_data) {
  g_dnd_active = FALSE;
  gboolean success = FALSE;
  if (g_dnd_channel != nullptr && selection_data != nullptr &&
      gtk_selection_data_get_length(selection_data) > 0) {
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(map, "type", fl_value_new_string("drop"));
    fl_value_set_string_take(map, "x", fl_value_new_float(static_cast<double>(x)));
    fl_value_set_string_take(map, "y", fl_value_new_float(static_cast<double>(y)));

    gchar **uris = gtk_selection_data_get_uris(selection_data);
    if (uris != nullptr) {
      FlValue *files = fl_value_new_list();
      for (gchar **u = uris; *u != nullptr; ++u) {
        g_autofree gchar *path = g_filename_from_uri(*u, nullptr, nullptr);
        if (path != nullptr) {
          fl_value_append_take(files, fl_value_new_string(path));
        } else {
          fl_value_append_take(files, fl_value_new_string(*u));
        }
      }
      fl_value_set_string_take(map, "files", files);
      g_strfreev(uris);
      success = TRUE;
    } else {
      g_autofree guchar *raw_text = gtk_selection_data_get_text(selection_data);
      if (raw_text != nullptr && raw_text[0] != '\0') {
        fl_value_set_string_take(
            map, "text",
            fl_value_new_string(reinterpret_cast<const gchar *>(raw_text)));
        success = TRUE;
      }
    }

    if (success) {
      fl_method_channel_invoke_method(g_dnd_channel, "onDropEvent", map,
                                      nullptr, nullptr, nullptr);
    }
  }
  gtk_drag_finish(context, success, FALSE, time);
}

}  // namespace

namespace libadwaitter {

void RegisterDndBridge(FlPluginRegistrar* registrar, FlView* view) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* dnd_channel = fl_method_channel_new(
      messenger, kDndChannelName, FL_METHOD_CODEC(codec));
  g_dnd_channel = dnd_channel;
  gtk_drag_dest_set(GTK_WIDGET(view), GTK_DEST_DEFAULT_ALL, kDropTargets,
                    G_N_ELEMENTS(kDropTargets), GDK_ACTION_COPY);
  g_signal_connect(view, "drag-motion", G_CALLBACK(on_view_drag_motion),
                   nullptr);
  g_signal_connect(view, "drag-leave", G_CALLBACK(on_view_drag_leave), nullptr);
  g_signal_connect(view, "drag-data-received",
                   G_CALLBACK(on_view_drag_data_received), nullptr);
}

}  // namespace libadwaitter
