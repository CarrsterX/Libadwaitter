#ifndef LIBADWAITTER_SETTINGS_SETTINGS_BRIDGE_H_
#define LIBADWAITTER_SETTINGS_SETTINGS_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void RegisterSettingsBridge(FlPluginRegistrar* registrar, GtkWindow* window);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_SETTINGS_SETTINGS_BRIDGE_H_
