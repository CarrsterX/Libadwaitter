#ifndef LIBADWAITTER_STYLE_STYLE_BRIDGE_H_
#define LIBADWAITTER_STYLE_STYLE_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void RegisterStyleBridge(FlPluginRegistrar* registrar, GtkWindow* window);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_STYLE_STYLE_BRIDGE_H_
