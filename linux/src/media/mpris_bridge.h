#ifndef LIBADWAITTER_MEDIA_MPRIS_BRIDGE_H_
#define LIBADWAITTER_MEDIA_MPRIS_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void RegisterMprisBridge(FlPluginRegistrar* registrar, GtkWindow* window);
void UnregisterMprisBridge();

}  // namespace libadwaitter

#endif  // LIBADWAITTER_MEDIA_MPRIS_BRIDGE_H_
