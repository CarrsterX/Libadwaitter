#ifndef LIBADWAITTER_PORTAL_PORTAL_BRIDGE_H_
#define LIBADWAITTER_PORTAL_PORTAL_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void RegisterPortalBridge(FlPluginRegistrar* registrar, GtkWindow* window);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_PORTAL_PORTAL_BRIDGE_H_
