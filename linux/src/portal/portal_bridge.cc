#include "portal/portal_bridge.h"

#include <cstring>

#include "common/portal_result.h"
#include "emoji/emoji_bridge.h"
#include "polkit/polkit_bridge.h"
#include "process/process_bridge.h"

namespace {

const char* kPortalChannelName = "libadwaitter/portal";

static FlMethodChannel *g_portal_channel = nullptr;
static GtkWindow *g_portal_main_window = nullptr;
static GHashTable *g_fdo_notif_by_nid = nullptr;
static GHashTable *g_fdo_nid_by_id = nullptr;
static guint g_fdo_action_sub_id = 0;
static guint g_fdo_closed_sub_id = 0;

struct FdoNotifMeta {
  gchar *id;
  gchar *payload;
};

static void fdo_notif_meta_free(gpointer data) {
  FdoNotifMeta *meta = static_cast<FdoNotifMeta *>(data);
  if (meta == nullptr)
    return;
  g_free(meta->id);
  g_free(meta->payload);
  g_free(meta);
}

static void dispatch_notification_event(const gchar *id, const gchar *action_id,
                                        const gchar *payload) {
  if (g_portal_main_window != nullptr) {
    gtk_window_present(g_portal_main_window);
  }
  if (g_portal_channel == nullptr)
    return;
  g_autoptr(FlValue) map = fl_value_new_map();
  fl_value_set_string_take(map, "id",
                           fl_value_new_string(id != nullptr ? id : "default"));
  fl_value_set_string_take(
      map, "actionId",
      fl_value_new_string(action_id != nullptr ? action_id : ""));
  fl_value_set_string_take(
      map, "payload", fl_value_new_string(payload != nullptr ? payload : ""));
  fl_method_channel_invoke_method(g_portal_channel, "onNotificationAction", map,
                                  nullptr, nullptr, nullptr);
}

static void on_notification_action_activated(GSimpleAction *action,
                                             GVariant *parameter,
                                             gpointer user_data) {
  if (parameter == nullptr)
    return;
  const gchar *id = "";
  const gchar *action_id = "";
  const gchar *payload = "";
  g_variant_get(parameter, "(&s&s&s)", &id, &action_id, &payload);
  dispatch_notification_event(id, action_id, payload);
}

static void on_fdo_notification_action_invoked(
    GDBusConnection *connection, const gchar *sender_name,
    const gchar *object_path, const gchar *interface_name,
    const gchar *signal_name, GVariant *parameters, gpointer user_data) {
  if (parameters == nullptr || g_fdo_notif_by_nid == nullptr)
    return;
  guint32 nid = 0;
  const gchar *action_key = "";
  g_variant_get(parameters, "(u&s)", &nid, &action_key);
  FdoNotifMeta *meta = static_cast<FdoNotifMeta *>(
      g_hash_table_lookup(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid)));
  if (meta == nullptr)
    return;
  const gchar *effective_action =
      (action_key != nullptr && strcmp(action_key, "default") == 0)
          ? ""
          : action_key;
  dispatch_notification_event(meta->id, effective_action, meta->payload);
}

static void on_fdo_notification_closed(
    GDBusConnection *connection, const gchar *sender_name,
    const gchar *object_path, const gchar *interface_name,
    const gchar *signal_name, GVariant *parameters, gpointer user_data) {
  if (parameters == nullptr || g_fdo_notif_by_nid == nullptr)
    return;
  guint32 nid = 0;
  guint32 reason = 0;
  g_variant_get(parameters, "(uu)", &nid, &reason);
  FdoNotifMeta *meta = static_cast<FdoNotifMeta *>(
      g_hash_table_lookup(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid)));
  if (meta != nullptr && g_fdo_nid_by_id != nullptr) {
    gpointer current = g_hash_table_lookup(g_fdo_nid_by_id, meta->id);
    if (GPOINTER_TO_UINT(current) == nid) {
      g_hash_table_remove(g_fdo_nid_by_id, meta->id);
    }
  }
  g_hash_table_remove(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid));
}

static void ensure_fdo_notifications_subscribed(GDBusConnection *bus) {
  if (bus == nullptr)
    return;
  if (g_fdo_notif_by_nid == nullptr) {
    g_fdo_notif_by_nid = g_hash_table_new_full(g_direct_hash, g_direct_equal,
                                               nullptr, fdo_notif_meta_free);
  }
  if (g_fdo_nid_by_id == nullptr) {
    g_fdo_nid_by_id =
        g_hash_table_new_full(g_str_hash, g_str_equal, g_free, nullptr);
  }
  if (g_fdo_action_sub_id == 0) {
    g_fdo_action_sub_id = g_dbus_connection_signal_subscribe(
        bus, "org.freedesktop.Notifications", "org.freedesktop.Notifications",
        "ActionInvoked", "/org/freedesktop/Notifications", nullptr,
        G_DBUS_SIGNAL_FLAGS_NONE, on_fdo_notification_action_invoked, nullptr,
        nullptr);
  }
  if (g_fdo_closed_sub_id == 0) {
    g_fdo_closed_sub_id = g_dbus_connection_signal_subscribe(
        bus, "org.freedesktop.Notifications", "org.freedesktop.Notifications",
        "NotificationClosed", "/org/freedesktop/Notifications", nullptr,
        G_DBUS_SIGNAL_FLAGS_NONE, on_fdo_notification_closed, nullptr, nullptr);
  }
}

typedef struct {
  FlMethodCall *method_call;
  GDBusConnection *connection;
  guint signal_id;
  bool return_screenshot_uri;
} PortalAsyncRequest;

static void portal_async_request_free(PortalAsyncRequest *req) {
  if (req == nullptr)
    return;
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

static void on_portal_request_response(
    GDBusConnection *connection, const gchar *sender_name,
    const gchar *object_path, const gchar *interface_name,
    const gchar *signal_name, GVariant *parameters, gpointer user_data) {
  PortalAsyncRequest *req = static_cast<PortalAsyncRequest *>(user_data);
  if (req == nullptr || req->method_call == nullptr)
    return;

  guint32 response_code = 2;
  g_autoptr(GVariant) results = nullptr;
  g_variant_get(parameters, "(u@a{sv})", &response_code, &results);

  g_autoptr(FlValue) reply = nullptr;
  if (response_code == 0) {
    if (req->return_screenshot_uri && results != nullptr) {
      const gchar *uri = nullptr;
      if (g_variant_lookup(results, "uri", "&s", &uri) && uri != nullptr) {
        reply =
            libadwaitter::BuildPortalResult("granted", fl_value_new_string(uri), nullptr);
      } else {
        reply = libadwaitter::BuildPortalResult("granted", nullptr, nullptr);
      }
    } else {
      reply = libadwaitter::BuildPortalResult("granted", fl_value_new_bool(TRUE), nullptr);
    }
  } else if (response_code == 1) {
    reply = libadwaitter::BuildPortalResult("cancelled", nullptr, nullptr);
  } else {
    reply = libadwaitter::BuildPortalResult("denied", nullptr,
                                "Permission denied by user or portal.");
  }

  fl_method_call_respond_success(req->method_call, reply, nullptr);
  portal_async_request_free(req);
}

static void on_portal_dbus_call_finished(GObject *source_object,
                                         GAsyncResult *res,
                                         gpointer user_data) {
  PortalAsyncRequest *req = static_cast<PortalAsyncRequest *>(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_finish(
      G_DBUS_CONNECTION(source_object), res, &error);
  if (error != nullptr) {
    g_autoptr(FlValue) reply =
        libadwaitter::BuildPortalResult("unsupported", nullptr, error->message);
    fl_method_call_respond_success(req->method_call, reply, nullptr);
    portal_async_request_free(req);
    return;
  }
  // Response will arrive via org.freedesktop.portal.Request::Response signal.
  (void)result;
}

static void
dispatch_portal_request(FlMethodCall *method_call, const char *interface_name,
                        const char *method_name, GVariant *parameters,
                        const char *expected_request_path, GDBusConnection *bus,
                        bool return_screenshot_uri) {
  PortalAsyncRequest *req = g_new0(PortalAsyncRequest, 1);
  req->method_call = FL_METHOD_CALL(g_object_ref(method_call));
  req->connection = G_DBUS_CONNECTION(g_object_ref(bus));
  req->return_screenshot_uri = return_screenshot_uri;

  req->signal_id = g_dbus_connection_signal_subscribe(
      bus, "org.freedesktop.portal.Desktop", "org.freedesktop.portal.Request",
      "Response", expected_request_path, nullptr,
      G_DBUS_SIGNAL_FLAGS_NO_MATCH_RULE, on_portal_request_response, req,
      nullptr);

  g_dbus_connection_call(
      bus, "org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
      interface_name, method_name, parameters, G_VARIANT_TYPE("(o)"),
      G_DBUS_CALL_FLAGS_NONE, -1, nullptr, on_portal_dbus_call_finished, req);
}

static gchar *build_portal_request_path(GDBusConnection *bus,
                                        const char *token) {
  const gchar *unique_name = g_dbus_connection_get_unique_name(bus);
  g_autofree gchar *sanitized =
      g_strdup(unique_name != nullptr ? unique_name : "");
  if (sanitized[0] == ':') {
    sanitized[0] = '_';
    for (gchar *p = sanitized + 1; *p != '\0'; ++p) {
      if (*p == '.')
        *p = '_';
    }
  }
  return g_strdup_printf("/org/freedesktop/portal/desktop/request/%s/%s",
                         sanitized[0] == '_' ? sanitized + 1 : sanitized,
                         token);
}

static void portal_method_call_handler(FlMethodChannel *channel,
                                       FlMethodCall *method_call,
                                       gpointer user_data) {
  GtkWindow *window = GTK_WINDOW(user_data);
  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getSandboxInfo") == 0) {
    gboolean is_flatpak = g_file_test("/.flatpak-info", G_FILE_TEST_EXISTS);
    const gchar *flatpak_id = g_getenv("FLATPAK_ID");
    const gchar *snap_dir = g_getenv("SNAP");
    const gchar *snap_name = g_getenv("SNAP_NAME");
    const gchar *wayland_display = g_getenv("WAYLAND_DISPLAY");

    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(
        map, "isFlatpak",
        fl_value_new_bool(is_flatpak || flatpak_id != nullptr));
    fl_value_set_string_take(
        map, "isSnap",
        fl_value_new_bool(snap_dir != nullptr || snap_name != nullptr));
    fl_value_set_string_take(map, "isWayland",
                             fl_value_new_bool(wayland_display != nullptr &&
                                               wayland_display[0] != '\0'));
    if (flatpak_id != nullptr) {
      fl_value_set_string_take(map, "flatpakId",
                               fl_value_new_string(flatpak_id));
    }
    if (snap_name != nullptr) {
      fl_value_set_string_take(map, "snapName", fl_value_new_string(snap_name));
    }
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "share") == 0) {
    const gchar *text = nullptr;
    FlValue *files_val = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "text")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        text = fl_value_get_string(v);
      }
      if ((v = fl_value_lookup_string(args, "filePaths")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_LIST &&
          fl_value_get_length(v) > 0) {
        files_val = v;
      }
    }
    if (files_val != nullptr) {
      FlValue *first = fl_value_get_list_value(files_val, 0);
      if (first != nullptr && fl_value_get_type(first) == FL_VALUE_TYPE_STRING) {
        g_autofree gchar *uri =
            g_filename_to_uri(fl_value_get_string(first), nullptr, nullptr);
        if (uri != nullptr) {
          g_autoptr(GError) err = nullptr;
          gtk_show_uri_on_window(window, uri, GDK_CURRENT_TIME, &err);
        }
      }
    }
    if (text != nullptr && text[0] != '\0') {
      GtkClipboard *clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
      if (clipboard != nullptr) {
        gtk_clipboard_set_text(clipboard, text, -1);
      }
    }
    g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "openUri") == 0) {
    const gchar *uri = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *uri_val = fl_value_lookup_string(args, "uri");
      if (uri_val != nullptr &&
          fl_value_get_type(uri_val) == FL_VALUE_TYPE_STRING) {
        uri = fl_value_get_string(uri_val);
      }
    }
    if (uri == nullptr) {
      g_autoptr(FlValue) reply =
          libadwaitter::BuildPortalResult("error", nullptr, "Missing uri argument.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    g_autoptr(GError) error = nullptr;
    if (gtk_show_uri_on_window(window, uri, GDK_CURRENT_TIME, &error)) {
      g_autoptr(FlValue) reply =
          libadwaitter::BuildPortalResult("granted", nullptr, nullptr);
      fl_method_call_respond_success(method_call, reply, nullptr);
    } else {
      g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult(
          "error", nullptr,
          error != nullptr ? error->message : "Failed to open URI.");
      fl_method_call_respond_success(method_call, reply, nullptr);
    }
  } else if (strcmp(method, "sendNotification") == 0) {
    const gchar *id = "default";
    const gchar *title = "";
    const gchar *body = nullptr;
    const gchar *icon_name = nullptr;
    const gchar *priority_str = "normal";
    const gchar *payload = "";
    const gchar *category = nullptr;
    FlValue *actions_val = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "id")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        id = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "title")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "body")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        body = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "iconName")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        icon_name = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "priority")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        priority_str = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "payload")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        payload = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "category")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        category = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "actions")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_LIST)
        actions_val = v;
    }
    gboolean is_flatpak = g_file_test("/.flatpak-info", G_FILE_TEST_EXISTS);
    if (!is_flatpak) {
      g_autoptr(GError) bus_err = nullptr;
      g_autoptr(GDBusConnection) bus =
          g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &bus_err);
      if (bus != nullptr) {
        ensure_fdo_notifications_subscribed(bus);
        guint32 replaces_id = 0;
        if (g_fdo_nid_by_id != nullptr) {
          replaces_id =
              GPOINTER_TO_UINT(g_hash_table_lookup(g_fdo_nid_by_id, id));
        }
        GVariantBuilder actions_builder;
        g_variant_builder_init(&actions_builder, G_VARIANT_TYPE("as"));
        g_variant_builder_add(&actions_builder, "s", "default");
        g_variant_builder_add(&actions_builder, "s", "Open");
        if (actions_val != nullptr) {
          size_t count = fl_value_get_length(actions_val);
          for (size_t i = 0; i < count; ++i) {
            FlValue *item = fl_value_get_list_value(actions_val, i);
            if (item != nullptr &&
                fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
              FlValue *aid_v = fl_value_lookup_string(item, "id");
              FlValue *label_v = fl_value_lookup_string(item, "label");
              if (aid_v != nullptr && label_v != nullptr &&
                  fl_value_get_type(aid_v) == FL_VALUE_TYPE_STRING &&
                  fl_value_get_type(label_v) == FL_VALUE_TYPE_STRING) {
                g_variant_builder_add(&actions_builder, "s",
                                      fl_value_get_string(aid_v));
                g_variant_builder_add(&actions_builder, "s",
                                      fl_value_get_string(label_v));
              }
            }
          }
        }
        GVariantBuilder hints_builder;
        g_variant_builder_init(&hints_builder, G_VARIANT_TYPE("a{sv}"));
        guchar urgency = 1;
        if (strcmp(priority_str, "low") == 0)
          urgency = 0;
        else if (strcmp(priority_str, "urgent") == 0 ||
                 strcmp(priority_str, "high") == 0)
          urgency = 2;
        g_variant_builder_add(&hints_builder, "{sv}", "urgency",
                              g_variant_new_byte(urgency));
        g_variant_builder_add(&hints_builder, "{sv}", "desktop-entry",
                              g_variant_new_string(libadwaitter::GetApplicationId()));
        if (category != nullptr && category[0] != '\0') {
          g_variant_builder_add(&hints_builder, "{sv}", "category",
                                g_variant_new_string(category));
        }
        const gchar *app_name = g_get_application_name();
        if (app_name == nullptr)
          app_name = libadwaitter::GetApplicationId();
        g_autoptr(GError) call_err = nullptr;
        g_autoptr(GVariant) res = g_dbus_connection_call_sync(
            bus, "org.freedesktop.Notifications",
            "/org/freedesktop/Notifications", "org.freedesktop.Notifications",
            "Notify",
            g_variant_new("(susssasa{sv}i)", app_name, replaces_id,
                          icon_name != nullptr ? icon_name : "", title,
                          body != nullptr ? body : "", &actions_builder,
                          &hints_builder, -1),
            G_VARIANT_TYPE("(u)"), G_DBUS_CALL_FLAGS_NONE, -1, nullptr,
            &call_err);
        if (res != nullptr) {
          guint32 nid = 0;
          g_variant_get(res, "(u)", &nid);
          FdoNotifMeta *meta = g_new0(FdoNotifMeta, 1);
          meta->id = g_strdup(id);
          meta->payload = g_strdup(payload);
          g_hash_table_replace(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid), meta);
          g_hash_table_replace(g_fdo_nid_by_id, g_strdup(id),
                               GUINT_TO_POINTER(nid));
          g_autoptr(FlValue) reply =
              libadwaitter::BuildPortalResult("granted", nullptr, nullptr);
          fl_method_call_respond_success(method_call, reply, nullptr);
          return;
        }
      }
    }
    g_autoptr(GNotification) notification = g_notification_new(title);
    if (body != nullptr)
      g_notification_set_body(notification, body);
    if (icon_name != nullptr) {
      g_autoptr(GIcon) icon = g_themed_icon_new(icon_name);
      g_notification_set_icon(notification, icon);
    }
#if GLIB_CHECK_VERSION(2, 70, 0)
    if (category != nullptr && category[0] != '\0') {
      g_notification_set_category(notification, category);
    }
#endif
    if (strcmp(priority_str, "low") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_LOW);
    } else if (strcmp(priority_str, "high") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_HIGH);
    } else if (strcmp(priority_str, "urgent") == 0) {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_URGENT);
    } else {
      g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_NORMAL);
    }
    g_notification_set_default_action_and_target_value(
        notification, "app.libadwaitter-notify",
        g_variant_new("(sss)", id, "", payload));
    if (actions_val != nullptr) {
      size_t count = fl_value_get_length(actions_val);
      for (size_t i = 0; i < count; ++i) {
        FlValue *item = fl_value_get_list_value(actions_val, i);
        if (item != nullptr && fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
          FlValue *aid_v = fl_value_lookup_string(item, "id");
          FlValue *label_v = fl_value_lookup_string(item, "label");
          if (aid_v != nullptr && label_v != nullptr &&
              fl_value_get_type(aid_v) == FL_VALUE_TYPE_STRING &&
              fl_value_get_type(label_v) == FL_VALUE_TYPE_STRING) {
            g_notification_add_button_with_target_value(
                notification, fl_value_get_string(label_v),
                "app.libadwaitter-notify",
                g_variant_new("(sss)", id, fl_value_get_string(aid_v),
                              payload));
          }
        }
      }
    }
    g_application_send_notification(g_application_get_default(), id,
                                    notification);
    g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "withdrawNotification") == 0) {
    const gchar *id = "default";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = fl_value_lookup_string(args, "id");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        id = fl_value_get_string(v);
      }
    }
    if (g_fdo_nid_by_id != nullptr) {
      guint32 nid = GPOINTER_TO_UINT(g_hash_table_lookup(g_fdo_nid_by_id, id));
      if (nid != 0) {
        g_autoptr(GDBusConnection) bus =
            g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
        if (bus != nullptr) {
          g_dbus_connection_call(
              bus, "org.freedesktop.Notifications",
              "/org/freedesktop/Notifications", "org.freedesktop.Notifications",
              "CloseNotification", g_variant_new("(u)", nid), nullptr,
              G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr, nullptr);
        }
        g_hash_table_remove(g_fdo_nid_by_id, id);
        if (g_fdo_notif_by_nid != nullptr) {
          g_hash_table_remove(g_fdo_notif_by_nid, GUINT_TO_POINTER(nid));
        }
      }
    }
    g_application_withdraw_notification(g_application_get_default(), id);
    g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "requestAdminAuthorization") == 0) {
    libadwaitter::HandleRequestAdminAuthorization(method_call, args);
  } else if (strcmp(method, "runElevated") == 0) {
    libadwaitter::HandleRunElevated(method_call, args);
  } else if (strcmp(method, "runCommand") == 0) {
    libadwaitter::HandleRunCommand(method_call, args);
  } else if (strcmp(method, "pickEmoji") == 0) {
    libadwaitter::HandlePickEmoji(method_call, args, window);
  } else if (strcmp(method, "openFiles") == 0) {
    const gchar *title = "Open File";
    gboolean multiple = FALSE;
    gboolean directory = FALSE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "title")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "multiple")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        multiple = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "directory")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        directory = fl_value_get_bool(v);
    }
    GtkFileChooserAction action = directory
                                      ? GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER
                                      : GTK_FILE_CHOOSER_ACTION_OPEN;
    GtkFileChooserNative *chooser =
        gtk_file_chooser_native_new(title, window, action, "_Open", "_Cancel");
    gtk_file_chooser_set_select_multiple(GTK_FILE_CHOOSER(chooser), multiple);
    gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(chooser));
    g_autoptr(FlValue) reply = nullptr;
    if (res == GTK_RESPONSE_ACCEPT) {
      FlValue *list = fl_value_new_list();
      GSList *files = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(chooser));
      for (GSList *iter = files; iter != nullptr; iter = iter->next) {
        gchar *path = static_cast<gchar *>(iter->data);
        fl_value_append_take(list, fl_value_new_string(path));
        g_free(path);
      }
      g_slist_free(files);
      reply = libadwaitter::BuildPortalResult("granted", list, nullptr);
    } else {
      reply = libadwaitter::BuildPortalResult("cancelled", nullptr, nullptr);
    }
    g_object_unref(chooser);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "saveFile") == 0) {
    const gchar *title = "Save File";
    const gchar *current_name = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "title")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        title = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "currentName")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        current_name = fl_value_get_string(v);
    }
    GtkFileChooserNative *chooser = gtk_file_chooser_native_new(
        title, window, GTK_FILE_CHOOSER_ACTION_SAVE, "_Save", "_Cancel");
    gtk_file_chooser_set_do_overwrite_confirmation(GTK_FILE_CHOOSER(chooser),
                                                   TRUE);
    if (current_name != nullptr) {
      gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(chooser),
                                        current_name);
    }
    gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(chooser));
    g_autoptr(FlValue) reply = nullptr;
    if (res == GTK_RESPONSE_ACCEPT) {
      g_autofree gchar *path =
          gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(chooser));
      reply = libadwaitter::BuildPortalResult(
          "granted", path != nullptr ? fl_value_new_string(path) : nullptr,
          nullptr);
    } else {
      reply = libadwaitter::BuildPortalResult("cancelled", nullptr, nullptr);
    }
    g_object_unref(chooser);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "inhibit") == 0) {
    const gchar *reason = "Application activity";
    gboolean idle = TRUE;
    gboolean suspend = FALSE;
    gboolean logout = FALSE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "reason")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
        reason = fl_value_get_string(v);
      if ((v = fl_value_lookup_string(args, "idle")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        idle = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "suspend")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        suspend = fl_value_get_bool(v);
      if ((v = fl_value_lookup_string(args, "logout")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
        logout = fl_value_get_bool(v);
    }
    int flags = 0;
    if (logout)
      flags |= GTK_APPLICATION_INHIBIT_LOGOUT;
    if (suspend)
      flags |= GTK_APPLICATION_INHIBIT_SUSPEND;
    if (idle)
      flags |= GTK_APPLICATION_INHIBIT_IDLE;
    guint cookie = gtk_application_inhibit(
        GTK_APPLICATION(g_application_get_default()), window,
        static_cast<GtkApplicationInhibitFlags>(flags), reason);
    g_autoptr(FlValue) reply = nullptr;
    if (cookie != 0) {
      g_autofree gchar *handle = g_strdup_printf("%u", cookie);
      reply =
          libadwaitter::BuildPortalResult("granted", fl_value_new_string(handle), nullptr);
    } else {
      reply = libadwaitter::BuildPortalResult("unsupported", nullptr,
                                  "Session inhibit not supported by desktop.");
    }
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "uninhibit") == 0) {
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = fl_value_lookup_string(args, "handle");
      if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        guint cookie = static_cast<guint>(
            g_ascii_strtoull(fl_value_get_string(v), nullptr, 10));
        if (cookie != 0) {
          gtk_application_uninhibit(
              GTK_APPLICATION(g_application_get_default()), cookie);
        }
      }
    }
    g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult("granted", nullptr, nullptr);
    fl_method_call_respond_success(method_call, reply, nullptr);
  } else if (strcmp(method, "requestBackground") == 0 ||
             strcmp(method, "requestCamera") == 0 ||
             strcmp(method, "takeScreenshot") == 0) {
    g_autoptr(GError) bus_error = nullptr;
    g_autoptr(GDBusConnection) bus =
        g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &bus_error);
    if (bus == nullptr) {
      g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult(
          "error", nullptr,
          bus_error != nullptr ? bus_error->message : "No session D-Bus.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }

    g_autofree gchar *token =
        g_strdup_printf("libadwaitter_%u", g_random_int());
    g_autofree gchar *request_path = build_portal_request_path(bus, token);

    GVariantBuilder options;
    g_variant_builder_init(&options, G_VARIANT_TYPE_VARDICT);
    g_variant_builder_add(&options, "{sv}", "handle_token",
                          g_variant_new_string(token));

    if (strcmp(method, "requestBackground") == 0) {
      const gchar *reason = "Allow running in background";
      gboolean autostart = FALSE;
      if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
        FlValue *v = nullptr;
        if ((v = fl_value_lookup_string(args, "reason")) != nullptr &&
            fl_value_get_type(v) == FL_VALUE_TYPE_STRING)
          reason = fl_value_get_string(v);
        if ((v = fl_value_lookup_string(args, "autostart")) != nullptr &&
            fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
          autostart = fl_value_get_bool(v);
      }
      g_variant_builder_add(&options, "{sv}", "reason",
                            g_variant_new_string(reason));
      g_variant_builder_add(&options, "{sv}", "autostart",
                            g_variant_new_boolean(autostart));
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
        FlValue *v = fl_value_lookup_string(args, "interactive");
        if (v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL)
          interactive = fl_value_get_bool(v);
      }
      g_variant_builder_add(&options, "{sv}", "interactive",
                            g_variant_new_boolean(interactive));
      dispatch_portal_request(
          method_call, "org.freedesktop.portal.Screenshot", "Screenshot",
          g_variant_new("(sa{sv})", "", &options), request_path, bus, true);
    }
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

}  // namespace

namespace libadwaitter {

void RegisterPortalBridge(FlPluginRegistrar* registrar, GtkWindow* window) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* portal_channel = fl_method_channel_new(
      messenger, kPortalChannelName, FL_METHOD_CODEC(codec));
  g_portal_channel = portal_channel;
  g_portal_main_window = window;
  fl_method_channel_set_method_call_handler(
      portal_channel, portal_method_call_handler, window, nullptr);

  GtkApplication* application = gtk_window_get_application(window);
  if (application != nullptr &&
      g_action_map_lookup_action(G_ACTION_MAP(application),
                                 "libadwaitter-notify") == nullptr) {
    g_autoptr(GSimpleAction) notify_action =
        g_simple_action_new("libadwaitter-notify", G_VARIANT_TYPE("(sss)"));
    g_signal_connect(notify_action, "activate",
                     G_CALLBACK(on_notification_action_activated), nullptr);
    g_action_map_add_action(G_ACTION_MAP(application), G_ACTION(notify_action));
  }
}

}  // namespace libadwaitter
