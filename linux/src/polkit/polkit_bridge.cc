#include "polkit/polkit_bridge.h"

#include <cstring>
#include <unistd.h>

#include "common/portal_result.h"

namespace {

static guint64 get_process_start_time() {
  g_autofree gchar *contents = nullptr;
  gsize len = 0;
  if (!g_file_get_contents("/proc/self/stat", &contents, &len, nullptr) ||
      contents == nullptr) {
    return 0;
  }
  const gchar *rparen = strrchr(contents, ')');
  if (rparen == nullptr)
    return 0;
  const gchar *p = rparen + 1;
  // Field 22 in /proc/self/stat is the 20th token after ')'.
  for (int field = 0; field < 20; ++field) {
    while (*p == ' ')
      ++p;
    if (*p == '\0')
      return 0;
    if (field == 19) {
      return g_ascii_strtoull(p, nullptr, 10);
    }
    while (*p != ' ' && *p != '\0')
      ++p;
  }
  return 0;
}

static void on_polkit_check_done(GObject *source_object, GAsyncResult *res,
                                 gpointer user_data) {
  FlMethodCall *method_call = FL_METHOD_CALL(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_finish(
      G_DBUS_CONNECTION(source_object), res, &error);

  g_autoptr(FlValue) reply = nullptr;
  if (error != nullptr || result == nullptr) {
    reply = libadwaitter::BuildPortalResult(
        "error", nullptr,
        error != nullptr ? error->message : "Polkit authorization call failed.");
  } else {
    gboolean is_authorized = FALSE;
    gboolean is_challenge = FALSE;
    g_autoptr(GVariant) details = nullptr;
    g_variant_get(result, "((bb@a{ss}))", &is_authorized, &is_challenge,
                  &details);
    gboolean dismissed = FALSE;
    if (details != nullptr) {
      const gchar *val = nullptr;
      if (g_variant_lookup(details, "polkit.dismissed", "&s", &val) &&
          val != nullptr && strcmp(val, "true") == 0) {
        dismissed = TRUE;
      }
    }
    if (is_authorized) {
      reply = libadwaitter::BuildPortalResult("granted", fl_value_new_bool(TRUE), nullptr);
    } else if (dismissed) {
      reply = libadwaitter::BuildPortalResult("cancelled", fl_value_new_bool(FALSE),
                                  "Authentication dismissed by user.");
    } else {
      reply = libadwaitter::BuildPortalResult("denied", fl_value_new_bool(FALSE),
                                  "Administrator authorization denied.");
    }
  }
  fl_method_call_respond_success(method_call, reply, nullptr);
  g_object_unref(method_call);
}

static void on_pkexec_communicate_done(GObject *source_object,
                                       GAsyncResult *res, gpointer user_data) {
  FlMethodCall *method_call = FL_METHOD_CALL(user_data);
  GSubprocess *proc = G_SUBPROCESS(source_object);
  g_autoptr(GError) error = nullptr;
  g_autofree gchar *stdout_buf = nullptr;
  g_autofree gchar *stderr_buf = nullptr;
  gboolean ok = g_subprocess_communicate_utf8_finish(proc, res, &stdout_buf,
                                                     &stderr_buf, &error);
  g_autoptr(FlValue) reply = nullptr;
  if (!ok) {
    reply = libadwaitter::BuildPortalResult(
        "error", nullptr,
        error != nullptr ? error->message : "Failed to run pkexec.");
  } else {
    gint exit_code =
        g_subprocess_get_if_exited(proc) ? g_subprocess_get_exit_status(proc) : -1;
    if (exit_code == 126) {
      reply = libadwaitter::BuildPortalResult("cancelled", nullptr,
                                  "Administrator prompt dismissed by user.");
    } else if (exit_code == 127) {
      reply = libadwaitter::BuildPortalResult(
          "denied", nullptr,
          (stderr_buf != nullptr && stderr_buf[0] != '\0')
              ? stderr_buf
              : "Authorization failed or executable not found.");
    } else {
      FlValue *val = fl_value_new_map();
      fl_value_set_string_take(val, "exitCode", fl_value_new_int(exit_code));
      fl_value_set_string_take(
          val, "stdout",
          fl_value_new_string(stdout_buf != nullptr ? stdout_buf : ""));
      fl_value_set_string_take(
          val, "stderr",
          fl_value_new_string(stderr_buf != nullptr ? stderr_buf : ""));
      reply = libadwaitter::BuildPortalResult("granted", val, nullptr);
    }
  }
  fl_method_call_respond_success(method_call, reply, nullptr);
  g_object_unref(method_call);
}

}  // namespace

namespace libadwaitter {

void HandleRequestAdminAuthorization(FlMethodCall* method_call, FlValue* args) {
    const gchar *action_id = "org.freedesktop.policykit.exec";
    gboolean allow_interaction = TRUE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "actionId")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        action_id = fl_value_get_string(v);
      }
      if ((v = fl_value_lookup_string(args, "allowUserInteraction")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL) {
        allow_interaction = fl_value_get_bool(v);
      }
    }
    g_autoptr(GError) bus_err = nullptr;
    g_autoptr(GDBusConnection) sys_bus =
        g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &bus_err);
    if (sys_bus == nullptr) {
      g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult(
          "error", nullptr,
          bus_err != nullptr ? bus_err->message
                             : "Failed to connect to system D-Bus.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    GVariantBuilder subject_details;
    g_variant_builder_init(&subject_details, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&subject_details, "{sv}", "pid",
                          g_variant_new_uint32(static_cast<guint32>(getpid())));
    g_variant_builder_add(&subject_details, "{sv}", "start-time",
                          g_variant_new_uint64(get_process_start_time()));
    g_variant_builder_add(&subject_details, "{sv}", "uid",
                          g_variant_new_int32(static_cast<gint32>(getuid())));

    GVariantBuilder details;
    g_variant_builder_init(&details, G_VARIANT_TYPE("a{ss}"));

    g_dbus_connection_call(
        sys_bus, "org.freedesktop.PolicyKit1",
        "/org/freedesktop/PolicyKit1/Authority",
        "org.freedesktop.PolicyKit1.Authority", "CheckAuthorization",
        g_variant_new("((sa{sv})sa{ss}us)", "unix-process", &subject_details,
                      action_id, &details, allow_interaction ? 1u : 0u, ""),
        G_VARIANT_TYPE("((bba{ss}))"), G_DBUS_CALL_FLAGS_NONE, G_MAXINT,
        nullptr, on_polkit_check_done, g_object_ref(method_call));

}

void HandleRunElevated(FlMethodCall* method_call, FlValue* args) {
    const gchar *executable = nullptr;
    FlValue *cmd_args = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *v = nullptr;
      if ((v = fl_value_lookup_string(args, "executable")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        executable = fl_value_get_string(v);
      }
      if ((v = fl_value_lookup_string(args, "arguments")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_LIST) {
        cmd_args = v;
      }
    }
    if (executable == nullptr || executable[0] == '\0') {
      g_autoptr(FlValue) reply =
          libadwaitter::BuildPortalResult("error", nullptr, "Missing executable argument.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    GPtrArray *argv = g_ptr_array_new();
    g_ptr_array_add(argv, const_cast<gchar *>("pkexec"));
    g_ptr_array_add(argv, const_cast<gchar *>(executable));
    if (cmd_args != nullptr) {
      size_t count = fl_value_get_length(cmd_args);
      for (size_t i = 0; i < count; ++i) {
        FlValue *item = fl_value_get_list_value(cmd_args, i);
        if (item != nullptr && fl_value_get_type(item) == FL_VALUE_TYPE_STRING) {
          g_ptr_array_add(argv,
                          const_cast<gchar *>(fl_value_get_string(item)));
        }
      }
    }
    g_ptr_array_add(argv, nullptr);

    g_autoptr(GError) spawn_err = nullptr;
    g_autoptr(GSubprocess) proc = g_subprocess_newv(
        reinterpret_cast<const gchar *const *>(argv->pdata),
        static_cast<GSubprocessFlags>(G_SUBPROCESS_FLAGS_STDOUT_PIPE |
                                      G_SUBPROCESS_FLAGS_STDERR_PIPE),
        &spawn_err);
    g_ptr_array_free(argv, TRUE);

    if (proc == nullptr) {
      g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult(
          "error", nullptr,
          spawn_err != nullptr ? spawn_err->message : "Failed to launch pkexec.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    g_subprocess_communicate_utf8_async(proc, nullptr, nullptr,
                                        on_pkexec_communicate_done,
                                        g_object_ref(method_call));

}

}  // namespace libadwaitter
