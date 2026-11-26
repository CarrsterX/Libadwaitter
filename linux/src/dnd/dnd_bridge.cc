#include "dnd/dnd_bridge.h"

#include <cstring>
#include <string>
#include <vector>

namespace {

const char* kDndChannelName = "libadwaitter/dnd";

static FlMethodChannel *g_dnd_channel = nullptr;
static FlView *g_dnd_view = nullptr;
static gboolean g_dnd_active = FALSE;
static std::vector<std::string> g_outgoing_files;
static std::string g_outgoing_text;

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

static void on_view_drag_data_get(GtkWidget *widget, GdkDragContext *context,
                                  GtkSelectionData *selection_data, guint info,
                                  guint time, gpointer user_data) {
  if (info == 1 && !g_outgoing_files.empty()) {
    std::vector<gchar *> uri_ptrs;
    uri_ptrs.reserve(g_outgoing_files.size() + 1);
    for (const auto &path : g_outgoing_files) {
      gchar *uri = nullptr;
      if (g_str_has_prefix(path.c_str(), "file://")) {
        uri = g_strdup(path.c_str());
      } else {
        uri = g_filename_to_uri(path.c_str(), nullptr, nullptr);
      }
      if (uri != nullptr) {
        uri_ptrs.push_back(uri);
      }
    }
    uri_ptrs.push_back(nullptr);
    if (uri_ptrs.size() > 1) {
      gtk_selection_data_set_uris(selection_data, uri_ptrs.data());
    }
    for (gchar *u : uri_ptrs) {
      g_free(u);
    }
  } else if (info == 2 && !g_outgoing_text.empty()) {
    gtk_selection_data_set_text(selection_data, g_outgoing_text.c_str(),
                                static_cast<gint>(g_outgoing_text.size()));
  }
}

static void on_view_drag_end(GtkWidget *widget, GdkDragContext *context,
                             gpointer user_data) {
  g_outgoing_files.clear();
  g_outgoing_text.clear();
}

static void on_dnd_method_call(FlMethodChannel *channel,
                               FlMethodCall *method_call, gpointer user_data) {
  const gchar *method = fl_method_call_get_name(method_call);
  if (strcmp(method, "startDrag") == 0) {
    FlValue *args = fl_method_call_get_args(method_call);
    if (g_dnd_view == nullptr || args == nullptr ||
        fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      fl_method_call_respond_success(method_call, fl_value_new_bool(FALSE),
                                     nullptr);
      return;
    }

    g_outgoing_files.clear();
    g_outgoing_text.clear();

    FlValue *files_val = fl_value_lookup_string(args, "files");
    if (files_val != nullptr &&
        fl_value_get_type(files_val) == FL_VALUE_TYPE_LIST) {
      size_t len = fl_value_get_length(files_val);
      for (size_t i = 0; i < len; ++i) {
        FlValue *item = fl_value_get_list_value(files_val, i);
        if (item != nullptr &&
            fl_value_get_type(item) == FL_VALUE_TYPE_STRING) {
          const gchar *s = fl_value_get_string(item);
          if (s != nullptr && s[0] != '\0') {
            g_outgoing_files.emplace_back(s);
          }
        }
      }
    }

    FlValue *text_val = fl_value_lookup_string(args, "text");
    if (text_val != nullptr &&
        fl_value_get_type(text_val) == FL_VALUE_TYPE_STRING) {
      const gchar *s = fl_value_get_string(text_val);
      if (s != nullptr && s[0] != '\0') {
        g_outgoing_text = s;
      }
    }

    if (g_outgoing_files.empty() && g_outgoing_text.empty()) {
      fl_method_call_respond_success(method_call, fl_value_new_bool(FALSE),
                                     nullptr);
      return;
    }

    gint x = -1;
    gint y = -1;
    FlValue *x_val = fl_value_lookup_string(args, "x");
    FlValue *y_val = fl_value_lookup_string(args, "y");
    if (x_val != nullptr && fl_value_get_type(x_val) == FL_VALUE_TYPE_FLOAT) {
      x = static_cast<gint>(fl_value_get_float(x_val));
    }
    if (y_val != nullptr && fl_value_get_type(y_val) == FL_VALUE_TYPE_FLOAT) {
      y = static_cast<gint>(fl_value_get_float(y_val));
    }

    GtkTargetList *target_list = gtk_target_list_new(nullptr, 0);
    if (!g_outgoing_files.empty()) {
      gtk_target_list_add(target_list,
                          gdk_atom_intern_static_string("text/uri-list"), 0, 1);
    }
    if (!g_outgoing_text.empty()) {
      gtk_target_list_add(
          target_list,
          gdk_atom_intern_static_string("text/plain;charset=utf-8"), 0, 2);
      gtk_target_list_add(target_list,
                          gdk_atom_intern_static_string("UTF8_STRING"), 0, 2);
      gtk_target_list_add(target_list,
                          gdk_atom_intern_static_string("text/plain"), 0, 2);
    }

    GdkDragContext *ctx = gtk_drag_begin_with_coordinates(
        GTK_WIDGET(g_dnd_view), target_list, GDK_ACTION_COPY, 1, nullptr, x, y);
    gtk_target_list_unref(target_list);

    if (ctx != nullptr) {
      gtk_drag_set_icon_name(
          ctx, !g_outgoing_files.empty() ? "text-x-generic" : "edit-copy", 0,
          0);
      fl_method_call_respond_success(method_call, fl_value_new_bool(TRUE),
                                     nullptr);
    } else {
      g_outgoing_files.clear();
      g_outgoing_text.clear();
      fl_method_call_respond_success(method_call, fl_value_new_bool(FALSE),
                                     nullptr);
    }
    return;
  }

  fl_method_call_respond_not_implemented(method_call, nullptr);
}

}  // namespace

namespace libadwaitter {

void RegisterDndBridge(FlPluginRegistrar* registrar, FlView* view) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* dnd_channel = fl_method_channel_new(
      messenger, kDndChannelName, FL_METHOD_CODEC(codec));
  g_dnd_channel = dnd_channel;
  g_dnd_view = view;
  fl_method_channel_set_method_call_handler(dnd_channel, on_dnd_method_call,
                                            nullptr, nullptr);
  gtk_drag_dest_set(GTK_WIDGET(view), GTK_DEST_DEFAULT_ALL, kDropTargets,
                    G_N_ELEMENTS(kDropTargets), GDK_ACTION_COPY);
  g_signal_connect(view, "drag-motion", G_CALLBACK(on_view_drag_motion),
                   nullptr);
  g_signal_connect(view, "drag-leave", G_CALLBACK(on_view_drag_leave), nullptr);
  g_signal_connect(view, "drag-data-received",
                   G_CALLBACK(on_view_drag_data_received), nullptr);
  g_signal_connect(view, "drag-data-get", G_CALLBACK(on_view_drag_data_get),
                   nullptr);
  g_signal_connect(view, "drag-end", G_CALLBACK(on_view_drag_end), nullptr);
}

}  // namespace libadwaitter
