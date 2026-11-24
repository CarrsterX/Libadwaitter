#ifndef LIBADWAITTER_TEXT_ACTIONS_TEXT_ACTIONS_BRIDGE_H_
#define LIBADWAITTER_TEXT_ACTIONS_TEXT_ACTIONS_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void RegisterTextActionsBridge(FlPluginRegistrar* registrar, GtkWindow* window);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_TEXT_ACTIONS_TEXT_ACTIONS_BRIDGE_H_
