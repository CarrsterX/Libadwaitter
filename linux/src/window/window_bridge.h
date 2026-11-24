#ifndef LIBADWAITTER_WINDOW_WINDOW_BRIDGE_H_
#define LIBADWAITTER_WINDOW_WINDOW_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void ApplyWindowShadowMargin(GtkWindow* window, gint margin);
void RegisterWindowBridge(FlPluginRegistrar* registrar, FlView* view,
                          GtkWindow* window);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_WINDOW_WINDOW_BRIDGE_H_
