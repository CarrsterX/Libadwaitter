#ifndef LIBADWAITTER_DND_DND_BRIDGE_H_
#define LIBADWAITTER_DND_DND_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void RegisterDndBridge(FlPluginRegistrar* registrar, FlView* view);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_DND_DND_BRIDGE_H_
