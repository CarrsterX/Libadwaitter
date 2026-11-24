#include "text_actions/text_actions_bridge.h"

#include <cstring>

namespace {

const char* kTextActionsChannelName = "libadwaitter/text_actions";

static gchar *strip_mnemonic(const gchar *raw) {
  if (raw == nullptr)
    return g_strdup("");
  GString *out = g_string_new("");
  for (const gchar *p = raw; *p != '\0'; ++p) {
    if (*p != '_')
      g_string_append_c(out, *p);
  }
  return g_string_free(out, FALSE);
}

// --- Native Linux Touch Text Magnifier (GTK3 + Cairo/Pango) ---

struct NativeMagnifierState {
  GtkWidget *window = nullptr;
  GtkWindow *parent = nullptr;
  gchar *text = nullptr;
  gchar *font_family = nullptr;
  gdouble target_x = 0.0;
  gint popup_width = 400;
  gint caret_index = 0;
  gint sel_start = 0;
  gint sel_end = 0;
  gboolean has_selection = FALSE;
  gdouble font_size = 14.0;
  guint32 text_color = 0xFFFFFFFF;
  guint32 bg_color = 0xFF222226;
  guint32 sel_color = 0x4D3584E4;
  guint32 cursor_color = 0xFF3584E4;
};

static NativeMagnifierState g_magnifier;

static void set_cairo_argb(cairo_t *cr, guint32 argb) {
  double a = ((argb >> 24) & 0xFF) / 255.0;
  double r = ((argb >> 16) & 0xFF) / 255.0;
  double g = ((argb >> 8) & 0xFF) / 255.0;
  double b = (argb & 0xFF) / 255.0;
  cairo_set_source_rgba(cr, r, g, b, a);
}

static gint utf8_char_to_byte_offset(const gchar *str, gint char_index) {
  if (str == nullptr || char_index <= 0)
    return 0;
  glong len = g_utf8_strlen(str, -1);
  if (char_index > len)
    char_index = static_cast<gint>(len);
  const gchar *ptr = g_utf8_offset_to_pointer(str, char_index);
  return static_cast<gint>(ptr - str);
}

static gboolean on_magnifier_draw(GtkWidget *widget, cairo_t *cr,
                                  gpointer user_data) {
  const double kW = 116.0;
  const double kBodyH = 76.0;
  const double kH = 85.0;
  const double kPad = 8.0;
  const double kLensW = 100.0;
  const double kLensH = 60.0;
  const double kR = 12.0;
  const double kArrowHalfW = 9.0;
  const double kPi = 3.14159265358979323846;

  // Transparent background across the full popup strip.
  cairo_save(cr);
  cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
  cairo_set_source_rgba(cr, 0, 0, 0, 0);
  cairo_paint(cr);
  cairo_restore(cr);

  double max_left = g_magnifier.popup_width - kW - 8.0;
  if (max_left < 8.0)
    max_left = 8.0;
  double left = g_magnifier.target_x - kW / 2.0;
  if (left < 8.0)
    left = 8.0;
  if (left > max_left)
    left = max_left;

  double arrow_cx = g_magnifier.target_x - left;
  double min_arrow = kR + kArrowHalfW + 2.0;
  double max_arrow = kW - kR - kArrowHalfW - 2.0;
  if (arrow_cx < min_arrow)
    arrow_cx = min_arrow;
  if (arrow_cx > max_arrow)
    arrow_cx = max_arrow;

  cairo_save(cr);
  cairo_translate(cr, left, 0.0);

  // Outer Libadwaita OSD popover path (rounded rect + bottom arrow).
  cairo_new_sub_path(cr);
  cairo_arc(cr, kW - kR, kR, kR, -kPi / 2, 0);
  cairo_arc(cr, kW - kR, kBodyH - kR, kR, 0, kPi / 2);
  cairo_line_to(cr, arrow_cx + kArrowHalfW, kBodyH);
  cairo_line_to(cr, arrow_cx, kH);
  cairo_line_to(cr, arrow_cx - kArrowHalfW, kBodyH);
  cairo_arc(cr, kR, kBodyH - kR, kR, kPi / 2, kPi);
  cairo_arc(cr, kR, kR, kR, kPi, 3 * kPi / 2);
  cairo_close_path(cr);

  cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.80);
  cairo_fill_preserve(cr);
  cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.10);
  cairo_set_line_width(cr, 1.0);
  cairo_stroke(cr);

  // Inner sharp 100x60 lens rectangle.
  cairo_save(cr);
  cairo_rectangle(cr, kPad, kPad, kLensW, kLensH);
  cairo_clip(cr);
  set_cairo_argb(cr, g_magnifier.bg_color);
  cairo_rectangle(cr, kPad, kPad, kLensW, kLensH);
  cairo_fill(cr);

  const gchar *text = g_magnifier.text != nullptr ? g_magnifier.text : "";
  PangoLayout *layout = pango_cairo_create_layout(cr);
  PangoFontDescription *desc = pango_font_description_new();
  pango_font_description_set_family(
      desc, (g_magnifier.font_family != nullptr &&
             g_magnifier.font_family[0] != '\0')
                ? g_magnifier.font_family
                : "Sans");
  pango_font_description_set_absolute_size(
      desc, g_magnifier.font_size * 2.0 * PANGO_SCALE);
  pango_layout_set_font_description(layout, desc);
  pango_layout_set_text(layout, text, -1);

  gint caret_byte = utf8_char_to_byte_offset(text, g_magnifier.caret_index);
  PangoRectangle caret_pos;
  pango_layout_get_cursor_pos(layout, caret_byte, &caret_pos, nullptr);

  int layout_w = 0, layout_h = 0;
  pango_layout_get_pixel_size(layout, &layout_w, &layout_h);
  double caret_x = static_cast<double>(caret_pos.x) / PANGO_SCALE;
  double dx = kPad + kLensW / 2.0 - caret_x;
  double dy = kPad + (kLensH - layout_h) / 2.0;

  if (g_magnifier.has_selection &&
      g_magnifier.sel_start != g_magnifier.sel_end) {
    gint s_byte = utf8_char_to_byte_offset(text, g_magnifier.sel_start);
    gint e_byte = utf8_char_to_byte_offset(text, g_magnifier.sel_end);
    PangoRectangle s_pos, e_pos;
    pango_layout_get_cursor_pos(layout, s_byte, &s_pos, nullptr);
    pango_layout_get_cursor_pos(layout, e_byte, &e_pos, nullptr);
    double sx = static_cast<double>(s_pos.x) / PANGO_SCALE;
    double ex = static_cast<double>(e_pos.x) / PANGO_SCALE;
    double left_x = sx < ex ? sx : ex;
    double right_x = sx < ex ? ex : sx;
    set_cairo_argb(cr, g_magnifier.sel_color);
    cairo_rectangle(cr, dx + left_x, dy - 6.0, right_x - left_x,
                    layout_h + 12.0);
    cairo_fill(cr);
  }

  cairo_move_to(cr, dx, dy);
  set_cairo_argb(cr, g_magnifier.text_color);
  pango_cairo_show_layout(cr, layout);

  if (!g_magnifier.has_selection) {
    set_cairo_argb(cr, g_magnifier.cursor_color);
    cairo_rectangle(cr, dx + caret_x - 1.25, dy, 2.5,
                    layout_h > 0 ? layout_h : g_magnifier.font_size * 2.0);
    cairo_fill(cr);
  }

  pango_font_description_free(desc);
  g_object_unref(layout);
  cairo_restore(cr);
  cairo_restore(cr);
  return TRUE;
}

static void ensure_native_magnifier_window(GtkWindow *parent) {
  if (g_magnifier.window != nullptr)
    return;
  GtkWidget *win = gtk_window_new(GTK_WINDOW_POPUP);
  gtk_window_set_transient_for(GTK_WINDOW(win), parent);
  gtk_window_set_accept_focus(GTK_WINDOW(win), FALSE);
  gtk_window_set_focus_on_map(GTK_WINDOW(win), FALSE);
  gtk_widget_set_can_focus(win, FALSE);
  gtk_window_set_decorated(GTK_WINDOW(win), FALSE);
  gtk_window_set_skip_taskbar_hint(GTK_WINDOW(win), TRUE);
  gtk_window_set_skip_pager_hint(GTK_WINDOW(win), TRUE);
  gtk_widget_set_app_paintable(win, TRUE);
  GdkScreen *screen = gtk_widget_get_screen(win);
  GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr) {
    gtk_widget_set_visual(win, visual);
  }
  gtk_widget_set_size_request(win, 116, 85);
  gtk_window_set_default_size(GTK_WINDOW(win), 116, 85);
  g_signal_connect(win, "draw", G_CALLBACK(on_magnifier_draw), nullptr);
  gtk_widget_realize(win);
  GdkWindow *gdk_win = gtk_widget_get_window(win);
  if (gdk_win != nullptr) {
    gdk_window_set_pass_through(gdk_win, TRUE);
  }
  g_magnifier.window = win;
  g_magnifier.parent = parent;
}

static void text_actions_method_call_handler(FlMethodChannel *channel,
                                             FlMethodCall *method_call,
                                             gpointer user_data) {
  GtkWindow *parent_window = GTK_WINDOW(user_data);
  const gchar *method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getLocalizedLabels") == 0) {
    g_autofree gchar *cut = strip_mnemonic(g_dgettext("gtk30", "_Cut"));
    g_autofree gchar *copy = strip_mnemonic(g_dgettext("gtk30", "_Copy"));
    g_autofree gchar *paste = strip_mnemonic(g_dgettext("gtk30", "_Paste"));
    g_autofree gchar *select_all =
        strip_mnemonic(g_dgettext("gtk30", "Select _All"));
    g_autofree gchar *insert_emoji =
        strip_mnemonic(g_dgettext("gtk30", "Insert _Emoji"));
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string_take(map, "cut", fl_value_new_string(cut));
    fl_value_set_string_take(map, "copy", fl_value_new_string(copy));
    fl_value_set_string_take(map, "paste", fl_value_new_string(paste));
    fl_value_set_string_take(map, "selectAll", fl_value_new_string(select_all));
    fl_value_set_string_take(map, "insertEmoji",
                             fl_value_new_string(insert_emoji));
    fl_method_call_respond_success(method_call, map, nullptr);
  } else if (strcmp(method, "getTextActions") == 0) {
    g_autoptr(FlValue) list = fl_value_new_list();
    fl_method_call_respond_success(method_call, list, nullptr);
  } else if (strcmp(method, "updateMagnifier") == 0) {
    FlValue *args = fl_method_call_get_args(method_call);
    if (parent_window != nullptr && args != nullptr &&
        fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      ensure_native_magnifier_window(parent_window);
      FlValue *x_val = fl_value_lookup_string(args, "x");
      FlValue *y_val = fl_value_lookup_string(args, "y");
      FlValue *text_val = fl_value_lookup_string(args, "text");
      FlValue *font_val = fl_value_lookup_string(args, "fontFamily");
      FlValue *size_val = fl_value_lookup_string(args, "fontSize");
      FlValue *caret_val = fl_value_lookup_string(args, "caretIndex");
      FlValue *s_val = fl_value_lookup_string(args, "selectionStart");
      FlValue *e_val = fl_value_lookup_string(args, "selectionEnd");
      FlValue *has_sel_val = fl_value_lookup_string(args, "hasSelection");
      FlValue *tc_val = fl_value_lookup_string(args, "textColor");
      FlValue *bg_val = fl_value_lookup_string(args, "bgColor");
      FlValue *sc_val = fl_value_lookup_string(args, "selectionColor");
      FlValue *cc_val = fl_value_lookup_string(args, "cursorColor");

      double x = (x_val != nullptr && fl_value_get_type(x_val) == FL_VALUE_TYPE_FLOAT)
                     ? fl_value_get_float(x_val)
                     : 0.0;
      double y = (y_val != nullptr && fl_value_get_type(y_val) == FL_VALUE_TYPE_FLOAT)
                     ? fl_value_get_float(y_val)
                     : 0.0;
      g_free(g_magnifier.text);
      g_magnifier.text = g_strdup(
          (text_val != nullptr && fl_value_get_type(text_val) == FL_VALUE_TYPE_STRING)
              ? fl_value_get_string(text_val)
              : "");
      g_free(g_magnifier.font_family);
      g_magnifier.font_family = g_strdup(
          (font_val != nullptr && fl_value_get_type(font_val) == FL_VALUE_TYPE_STRING)
              ? fl_value_get_string(font_val)
              : "Sans");
      if (size_val != nullptr && fl_value_get_type(size_val) == FL_VALUE_TYPE_FLOAT)
        g_magnifier.font_size = fl_value_get_float(size_val);
      if (caret_val != nullptr && fl_value_get_type(caret_val) == FL_VALUE_TYPE_INT)
        g_magnifier.caret_index = static_cast<gint>(fl_value_get_int(caret_val));
      if (s_val != nullptr && fl_value_get_type(s_val) == FL_VALUE_TYPE_INT)
        g_magnifier.sel_start = static_cast<gint>(fl_value_get_int(s_val));
      if (e_val != nullptr && fl_value_get_type(e_val) == FL_VALUE_TYPE_INT)
        g_magnifier.sel_end = static_cast<gint>(fl_value_get_int(e_val));
      if (has_sel_val != nullptr && fl_value_get_type(has_sel_val) == FL_VALUE_TYPE_BOOL)
        g_magnifier.has_selection = fl_value_get_bool(has_sel_val);
      if (tc_val != nullptr && fl_value_get_type(tc_val) == FL_VALUE_TYPE_INT)
        g_magnifier.text_color = static_cast<guint32>(fl_value_get_int(tc_val));
      if (bg_val != nullptr && fl_value_get_type(bg_val) == FL_VALUE_TYPE_INT)
        g_magnifier.bg_color = static_cast<guint32>(fl_value_get_int(bg_val));
      if (sc_val != nullptr && fl_value_get_type(sc_val) == FL_VALUE_TYPE_INT)
        g_magnifier.sel_color = static_cast<guint32>(fl_value_get_int(sc_val));
      if (cc_val != nullptr && fl_value_get_type(cc_val) == FL_VALUE_TYPE_INT)
        g_magnifier.cursor_color = static_cast<guint32>(fl_value_get_int(cc_val));

      g_magnifier.target_x = x;
      if (!gtk_widget_get_visible(g_magnifier.window)) {
        GtkWidget *fl_view = GTK_WIDGET(
            g_object_get_data(G_OBJECT(parent_window), "libadwaitter-fl-view"));
        gint view_x = 0, view_y = 0;
        gint strip_w = gtk_widget_get_allocated_width(GTK_WIDGET(parent_window));
        if (fl_view != nullptr) {
          strip_w = gtk_widget_get_allocated_width(fl_view);
          gtk_widget_translate_coordinates(fl_view, GTK_WIDGET(parent_window),
                                           0, 0, &view_x, &view_y);
        }
        if (strip_w < 132)
          strip_w = 132;
        g_magnifier.popup_width = strip_w;
        gtk_widget_set_size_request(g_magnifier.window, strip_w, 85);
        gtk_window_resize(GTK_WINDOW(g_magnifier.window), strip_w, 85);
        GdkWindow *popup_gdk = gtk_widget_get_window(g_magnifier.window);
        if (popup_gdk != nullptr) {
          gint shadow_margin = GPOINTER_TO_INT(g_object_get_data(
              G_OBJECT(parent_window), "libadwaitter-shadow-margin"));
          GdkRectangle anchor = {
              view_x + shadow_margin,
              view_y + shadow_margin + static_cast<int>(y + 0.5),
              strip_w,
              1};
          gdk_window_move_to_rect(popup_gdk, &anchor, GDK_GRAVITY_NORTH_WEST,
                                  GDK_GRAVITY_SOUTH_WEST,
                                  static_cast<GdkAnchorHints>(0), 0, 0);
        }
        gtk_widget_show(g_magnifier.window);
      }
      gtk_widget_queue_draw(g_magnifier.window);
      g_autoptr(FlValue) ok = fl_value_new_bool(TRUE);
      fl_method_call_respond_success(method_call, ok, nullptr);
    } else {
      g_autoptr(FlValue) ok = fl_value_new_bool(FALSE);
      fl_method_call_respond_success(method_call, ok, nullptr);
    }
  } else if (strcmp(method, "hideMagnifier") == 0) {
    if (g_magnifier.window != nullptr &&
        gtk_widget_get_visible(g_magnifier.window)) {
      gtk_widget_hide(g_magnifier.window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

}  // namespace

namespace libadwaitter {

void RegisterTextActionsBridge(FlPluginRegistrar* registrar,
                               GtkWindow* window) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* text_actions_channel = fl_method_channel_new(
      messenger, kTextActionsChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      text_actions_channel, text_actions_method_call_handler, window, nullptr);
}

}  // namespace libadwaitter
