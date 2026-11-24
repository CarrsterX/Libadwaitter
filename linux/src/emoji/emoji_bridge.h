#ifndef LIBADWAITTER_EMOJI_EMOJI_BRIDGE_H_
#define LIBADWAITTER_EMOJI_EMOJI_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

namespace libadwaitter {

void HandlePickEmoji(FlMethodCall* method_call, FlValue* args,
                     GtkWindow* window);

}  // namespace libadwaitter

#endif  // LIBADWAITTER_EMOJI_EMOJI_BRIDGE_H_
