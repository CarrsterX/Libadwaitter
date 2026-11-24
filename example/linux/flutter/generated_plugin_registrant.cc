//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <libadwaitter/libadwaitter_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) libadwaitter_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LibadwaitterPlugin");
  libadwaitter_plugin_register_with_registrar(libadwaitter_registrar);
}
