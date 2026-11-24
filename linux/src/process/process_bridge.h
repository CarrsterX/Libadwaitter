#ifndef LIBADWAITTER_PROCESS_PROCESS_BRIDGE_H_
#define LIBADWAITTER_PROCESS_PROCESS_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>

namespace libadwaitter {

void HandleRunCommand(FlMethodCall* method_call, FlValue* args);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_PROCESS_PROCESS_BRIDGE_H_
