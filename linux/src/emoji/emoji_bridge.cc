#include "emoji/emoji_bridge.h"

#include "common/portal_result.h"

namespace {

struct EmojiPickerState {
  FlMethodCall *method_call;
  GtkWidget *entry;
  GtkWidget *view;
  gboolean finished;
};

static EmojiPickerState *g_emoji_picker = nullptr;

static void emoji_picker_finish(const char *status, const gchar *emoji) {
  if (g_emoji_picker == nullptr || g_emoji_picker->finished)
    return;
  EmojiPickerState *state = g_emoji_picker;
  state->finished = TRUE;
  g_emoji_picker = nullptr;

  g_autoptr(FlValue) reply = libadwaitter::BuildPortalResult(
      status, emoji != nullptr ? fl_value_new_string(emoji) : nullptr, nullptr);
  fl_method_call_respond_success(state->method_call, reply, nullptr);
  g_object_unref(state->method_call);

  if (state->entry != nullptr) {
    gtk_widget_destroy(state->entry);
  }
  if (state->view != nullptr) {
    gtk_widget_grab_focus(state->view);
  }
  g_free(state);
}

static void on_emoji_entry_changed(GtkEditable *editable, gpointer user_data) {
  const gchar *text = gtk_entry_get_text(GTK_ENTRY(editable));
  if (text != nullptr && text[0] != '\0') {
    emoji_picker_finish("granted", text);
  }
}

static gboolean on_emoji_entry_key_press(GtkWidget *widget, GdkEventKey *event,
                                         gpointer user_data) {
  if (event != nullptr && event->keyval == GDK_KEY_Escape) {
    emoji_picker_finish("cancelled", nullptr);
    return TRUE;
  }
  return FALSE;
}

}  // namespace

namespace libadwaitter {

void HandlePickEmoji(FlMethodCall* method_call, FlValue* args,
                     GtkWindow* window) {
    GtkWidget *overlay = GTK_WIDGET(
        g_object_get_data(G_OBJECT(window), "libadwaitter-root-overlay"));
    GtkWidget *view_w =
        GTK_WIDGET(g_object_get_data(G_OBJECT(window), "libadwaitter-fl-view"));
    if (overlay == nullptr) {
      g_autoptr(FlValue) reply =
          libadwaitter::BuildPortalResult("unsupported", nullptr, "Overlay unavailable.");
      fl_method_call_respond_success(method_call, reply, nullptr);
      return;
    }
    if (g_emoji_picker != nullptr) {
      emoji_picker_finish("cancelled", nullptr);
    }
    gint x = 200;
    gint y = 200;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue *xv = fl_value_lookup_string(args, "x");
      FlValue *yv = fl_value_lookup_string(args, "y");
      if (xv != nullptr && fl_value_get_type(xv) == FL_VALUE_TYPE_FLOAT)
        x = static_cast<gint>(fl_value_get_float(xv));
      if (yv != nullptr && fl_value_get_type(yv) == FL_VALUE_TYPE_FLOAT)
        y = static_cast<gint>(fl_value_get_float(yv));
    }
    GtkWidget *entry = gtk_entry_new();
    gtk_widget_set_size_request(entry, 1, 1);
    gtk_widget_set_halign(entry, GTK_ALIGN_START);
    gtk_widget_set_valign(entry, GTK_ALIGN_START);
    gtk_widget_set_margin_start(entry, x > 0 ? x : 0);
    gtk_widget_set_margin_top(entry, y > 0 ? y : 0);
    gtk_widget_set_opacity(entry, 0.0);
    gtk_overlay_add_overlay(GTK_OVERLAY(overlay), entry);
    gtk_widget_show(entry);
    gtk_widget_grab_focus(entry);

    g_emoji_picker = g_new0(EmojiPickerState, 1);
    g_emoji_picker->method_call = FL_METHOD_CALL(g_object_ref(method_call));
    g_emoji_picker->entry = entry;
    g_emoji_picker->view = view_w;

    g_signal_connect(entry, "changed", G_CALLBACK(on_emoji_entry_changed),
                     nullptr);
    g_signal_connect(entry, "key-press-event",
                     G_CALLBACK(on_emoji_entry_key_press), nullptr);
    g_signal_emit_by_name(entry, "insert-emoji");

}

}  // namespace libadwaitter
