#ifndef LIBADWAITTER_COMMON_PORTAL_RESULT_H_
#define LIBADWAITTER_COMMON_PORTAL_RESULT_H_

#include <flutter_linux/flutter_linux.h>

namespace libadwaitter {

FlValue* BuildPortalResult(const char* status, FlValue* value_take,
                           const char* error_message);

inline const gchar* GetApplicationId() {
  const gchar* prg = g_get_prgname();
  return (prg != nullptr && prg[0] != '\0') ? prg : "dev.libadwaitter.App";
}

}  // namespace libadwaitter

#endif  // LIBADWAITTER_COMMON_PORTAL_RESULT_H_
