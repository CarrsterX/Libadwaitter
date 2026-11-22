## 1.0.0-alpha

* Initial pre-alpha release of **Libadwaitter**, the GNOME Libadwaita 1.10+ suite for Flutter on Linux (Wayland/X11) and cross-platform UI via `adwaitter`.
* Added Linux GTK3 runner integration (`dart run libadwaitter:setup`): frameless CSD window management, drag/resize edges, minimize/maximize/fullscreen, native multi-window (`AdwSubWindow`), and 9-slice CSD drop shadows with `gdk_window_set_shadow_width`.
* Added `AdwPortal` native bridge for XDG Desktop Portals (`openUri`, `sendNotification`, `withdrawNotification`, `openFiles`, `saveFile`, `requestBackground`, `requestCamera`, `takeScreenshot`, `inhibit`, `uninhibit`, `getSandboxInfo`) with Android `openUri` support.
* Re-exports the complete `adwaitter` widget catalog and design system.
