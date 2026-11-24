#include "my_application.h"

#include <flutter_linux/flutter_linux.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char **dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void apply_window_shadow_margin(GtkWindow *window, gint margin) {
  if (window == nullptr)
    return;
  GdkWindow *gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win == nullptr)
    return;
  gint w = gtk_widget_get_allocated_width(GTK_WIDGET(window));
  gint h = gtk_widget_get_allocated_height(GTK_WIDGET(window));
  if (w > margin * 2 && h > margin * 2) {
    gdk_window_set_shadow_width(gdk_win, margin, margin, margin, margin);
  }
}

static void on_window_size_allocate(GtkWidget *widget,
                                    GtkAllocation *allocation,
                                    gpointer user_data) {
  gint margin = GPOINTER_TO_INT(
      g_object_get_data(G_OBJECT(widget), "libadwaitter-shadow-margin"));
  if (margin >= 0) {
    apply_window_shadow_margin(GTK_WINDOW(widget), margin);
  }
}

static gboolean window_draw_cb(GtkWidget *widget, cairo_t *cr,
                               gpointer user_data) {
  cairo_save(cr);
  cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
  cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
  cairo_paint(cr);
  cairo_restore(cr);
  return FALSE;
}

static void first_frame_cb(MyApplication *self, FlView *view) {
  GtkWidget *toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  gtk_widget_show(toplevel);
  if (GTK_IS_WINDOW(toplevel)) {
    gint margin = GPOINTER_TO_INT(
        g_object_get_data(G_OBJECT(toplevel), "libadwaitter-shadow-margin"));
    apply_window_shadow_margin(GTK_WINDOW(toplevel), margin);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication *application) {
  g_setenv("GTK_USE_PORTAL", "1", FALSE);
  MyApplication *self = MY_APPLICATION(application);

  // Set Wayland xdg_toplevel app_id / prgname so compositors match .desktop &
  // icon
  g_set_prgname(APPLICATION_ID);
  g_set_application_name("Adwaitter Demo");

  GtkWindow *window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  // Account for 24px CSD shadow margin on each side so the visible window
  // starts at 1000x720 (exact adwaita-1-demo default-width/default-height)
  // identically in both debug and release builds.
  constexpr gint kInitialShadowMargin = 24;
  g_object_set_data(G_OBJECT(window), "libadwaitter-shadow-margin",
                    GINT_TO_POINTER(kInitialShadowMargin));
  gtk_window_set_default_size(window, 1000 + kInitialShadowMargin * 2,
                              720 + kInitialShadowMargin * 2);

  // Enforce Libadwaita's standard minimum window dimensions (360x294)
  GdkGeometry min_geometry = {};
  min_geometry.min_width = 360 + kInitialShadowMargin * 2;
  min_geometry.min_height = 294 + kInitialShadowMargin * 2;
  gtk_window_set_geometry_hints(window, nullptr, &min_geometry,
                                GDK_HINT_MIN_SIZE);

  // Configure RGBA visual for alpha transparency and rounded corners
  GdkScreen *screen = gtk_window_get_screen(window);
  GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr && gdk_screen_is_composited(screen)) {
    gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);
    gtk_widget_set_visual(GTK_WIDGET(window), visual);
  }

  // Hook draw signal to clear the Cairo surface to transparent black
  g_signal_connect(window, "draw", G_CALLBACK(window_draw_cb), nullptr);
  g_signal_connect(window, "size-allocate", G_CALLBACK(on_window_size_allocate),
                   nullptr);

  // Apply transparent GTK CSS rule preventing opaque background drawing
  GtkCssProvider *css_provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(
      css_provider,
      "window, .background, decoration { background-color: transparent "
      "!important; background: transparent !important; border: none "
      "!important; outline: none !important; box-shadow: none !important; }",
      -1, nullptr);
  gtk_style_context_add_provider_for_screen(screen,
                                            GTK_STYLE_PROVIDER(css_provider),
                                            GTK_STYLE_PROVIDER_PRIORITY_USER);

  // Disable server-side decorations (SSD) to enable in-app client-side
  // decorations (CSD). Setting a 0x0 empty titlebar forces KWin (KDE
  // Wayland/X11) to honor CSD instead of drawing server-side window frames.
  GtkWidget *empty_titlebar = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_size_request(empty_titlebar, 0, 0);
  gtk_window_set_titlebar(window, empty_titlebar);
  gtk_window_set_decorated(window, FALSE);

  gtk_window_set_title(window, "Adwaitter Demo");

  g_autofree gchar *exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path != nullptr) {
    g_autofree gchar *exe_dir = g_path_get_dirname(exe_path);
    g_autofree gchar *icon_path =
        g_build_filename(exe_dir, "data", "adwaitter_demo.png", nullptr);
    if (g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
      gtk_window_set_icon_from_file(window, icon_path, nullptr);
    }
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView *view = fl_view_new(project);
  // Configure FlView background as fully transparent (alpha = 0.0)
  GdkRGBA background_color = {0.0, 0.0, 0.0, 0.0};
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  GtkWidget *root_overlay = gtk_overlay_new();
  gtk_container_add(GTK_CONTAINER(root_overlay), GTK_WIDGET(view));
  gtk_widget_show(root_overlay);
  gtk_container_add(GTK_CONTAINER(window), root_overlay);
  g_object_set_data(G_OBJECT(window), "libadwaitter-root-overlay",
                    root_overlay);

  // Show the window when Flutter renders.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  // Registers LibadwaitterPlugin and all native Linux bridges automatically.
  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication *application,
                                                  gchar ***arguments,
                                                  int *exit_status) {
  MyApplication *self = MY_APPLICATION(application);
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
static void my_application_startup(GApplication *application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication *application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject *object) {
  MyApplication *self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_init(MyApplication *self) {}

static void my_application_class_init(MyApplicationClass *klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

MyApplication *my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
