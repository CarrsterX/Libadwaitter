#include "process/process_bridge.h"

#include <cstring>

#include "common/portal_result.h"

namespace {

static void on_command_communicate_done(GObject *source_object,
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
        error != nullptr ? error->message : "Failed to run command.");
  } else {
    gint exit_code =
        g_subprocess_get_if_exited(proc) ? g_subprocess_get_exit_status(proc) : -1;
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
  fl_method_call_respond_success(method_call, reply, nullptr);
  g_object_unref(method_call);
}

}  // namespace

namespace libadwaitter {

void HandleRunCommand(FlMethodCall* method_call, FlValue* args) {
    const gchar *executable = nullptr;
    const gchar *working_dir = nullptr;
    gboolean detached = FALSE;
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
      if ((v = fl_value_lookup_string(args, "workingDirectory")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_STRING) {
        working_dir = fl_value_get_string(v);
      }
      if ((v = fl_value_lookup_string(args, "detached")) != nullptr &&
          fl_value_get_type(v) == FL_VALUE_TYPE_BOOL) {
        detached = fl_value_get_bool(v);
      }
    }
    if (executable == nullptr || executable[0] == '\0') {
      g_autoptr(FlValue) reply =
          libadwaitter::BuildPortalResult("error", nullptr, "Missing executable argument.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    GPtrArray *argv = g_ptr_array_new();
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

    GSubprocessFlags flags =
        detached ? G_SUBPROCESS_FLAGS_NONE
                 : static_cast<GSubprocessFlags>(G_SUBPROCESS_FLAGS_STDOUT_PIPE |
                                                 G_SUBPROCESS_FLAGS_STDERR_PIPE);
    g_autoptr(GSubprocessLauncher) launcher = g_subprocess_launcher_new(flags);
    if (working_dir != nullptr && working_dir[0] != '\0') {
      g_subprocess_launcher_set_cwd(launcher, working_dir);
    }

    g_autoptr(GError) spawn_err = nullptr;
    g_autoptr(GSubprocess) proc = g_subprocess_launcher_spawnv(
        launcher, reinterpret_cast<const gchar *const *>(argv->pdata),
        &spawn_err);
    g_ptr_array_free(argv, TRUE);

    if (proc == nullptr) {
      g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult(
          "error", nullptr,
          spawn_err != nullptr ? spawn_err->message
                               : "Failed to launch command.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    if (detached) {
      FlValue *val = fl_value_new_map();
      fl_value_set_string_take(val, "exitCode", fl_value_new_int(0));
      fl_value_set_string_take(val, "stdout", fl_value_new_string(""));
      fl_value_set_string_take(val, "stderr", fl_value_new_string(""));
      g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult("granted", val, nullptr);
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    g_subprocess_communicate_utf8_async(proc, nullptr, nullptr,
                                        on_command_communicate_done,
                                        g_object_ref(method_call));

}

}  // namespace libadwaitter
