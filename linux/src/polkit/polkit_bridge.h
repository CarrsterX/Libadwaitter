#ifndef LIBADWAITTER_POLKIT_POLKIT_BRIDGE_H_
#define LIBADWAITTER_POLKIT_POLKIT_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>

namespace libadwaitter {

void HandleRequestAdminAuthorization(FlMethodCall* method_call, FlValue* args);
void HandleRunElevated(FlMethodCall* method_call, FlValue* args);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_POLKIT_POLKIT_BRIDGE_H_
