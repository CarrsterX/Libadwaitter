#include "common/portal_result.h"

namespace libadwaitter {

FlValue* BuildPortalResult(const char* status, FlValue* value_take,
                           const char* error_message) {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "status", fl_value_new_string(status));
  if (value_take != nullptr) {
    fl_value_set_string_take(map, "value", value_take);
  }
  if (error_message != nullptr && error_message[0] != '\0') {
    fl_value_set_string_take(map, "errorMessage",
                             fl_value_new_string(error_message));
  }
  return map;
}

}  // namespace libadwaitter
