cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "libadwaitter")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "libadwaitter_plugin")

add_library(${PLUGIN_NAME} SHARED
  "src/libadwaitter_plugin.cc"
  "src/common/portal_result.cc"
  "src/window/window_bridge.cc"
  "src/settings/settings_bridge.cc"
  "src/style/style_bridge.cc"
  "src/portal/portal_bridge.cc"
  "src/polkit/polkit_bridge.cc"
  "src/process/process_bridge.cc"
  "src/emoji/emoji_bridge.cc"
  "src/media/mpris_bridge.cc"
  "src/tray/tray_bridge.cc"
  "src/dnd/dnd_bridge.cc"
  "src/text_actions/text_actions_bridge.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/src")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

set(libadwaitter_bundled_libraries
  ""
  PARENT_SCOPE
)
