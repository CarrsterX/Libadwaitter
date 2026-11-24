#ifndef LIBADWAITTER_TRAY_TRAY_BRIDGE_H_
#define LIBADWAITTER_TRAY_TRAY_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void RegisterTrayBridge(FlPluginRegistrar* registrar, GtkWindow* window);
void UnregisterTrayBridge();

}  // namespace libadwaitter

#endif  // LIBADWAITTER_TRAY_TRAY_BRIDGE_H_
