#include "libadwaitter/libadwaitter_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include "dnd/dnd_bridge.h"
#include "media/mpris_bridge.h"
#include "portal/portal_bridge.h"
#include "settings/settings_bridge.h"
#include "style/style_bridge.h"
#include "text_actions/text_actions_bridge.h"
#include "tray/tray_bridge.h"
#include "window/window_bridge.h"

#define LIBADWAITTER_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), libadwaitter_plugin_get_type(), \
                              LibadwaitterPlugin))

struct _LibadwaitterPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(LibadwaitterPlugin, libadwaitter_plugin, g_object_get_type())

static void on_application_shutdown(GApplication* application,
                                    gpointer user_data) {
  libadwaitter::UnregisterMprisBridge();
  libadwaitter::UnregisterTrayBridge();
}

static void libadwaitter_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(libadwaitter_plugin_parent_class)->dispose(object);
}

static void libadwaitter_plugin_class_init(LibadwaitterPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = libadwaitter_plugin_dispose;
}

static void libadwaitter_plugin_init(LibadwaitterPlugin* self) {}

void libadwaitter_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  LibadwaitterPlugin* plugin = LIBADWAITTER_PLUGIN(
      g_object_new(libadwaitter_plugin_get_type(), nullptr));

  FlView* view = fl_plugin_registrar_get_view(registrar);
  GtkWidget* toplevel =
      view != nullptr ? gtk_widget_get_toplevel(GTK_WIDGET(view)) : nullptr;
  GtkWindow* window =
      (toplevel != nullptr && GTK_IS_WINDOW(toplevel)) ? GTK_WINDOW(toplevel)
                                                       : nullptr;

  if (window != nullptr) {
    libadwaitter::RegisterWindowBridge(registrar, view, window);
    libadwaitter::RegisterSettingsBridge(registrar, window);
    libadwaitter::RegisterStyleBridge(registrar, window);
    libadwaitter::RegisterPortalBridge(registrar, window);
    libadwaitter::RegisterMprisBridge(registrar, window);
    libadwaitter::RegisterTrayBridge(registrar, window);
    libadwaitter::RegisterTextActionsBridge(registrar, window);

    GtkApplication* app = gtk_window_get_application(window);
    if (app != nullptr) {
      g_signal_connect(app, "shutdown", G_CALLBACK(on_application_shutdown),
                       nullptr);
    }
  }

  if (view != nullptr) {
    libadwaitter::RegisterDndBridge(registrar, view);
  }

  g_object_unref(plugin);
}
