## 1.0.0-alpha.7

* Refactored all Linux native bridges into a modular Feature-Driven Design (FDD) Flutter Linux plugin (`LibadwaitterPlugin` under `linux/src/`) so new bridges are compiled and registered automatically without duplicating C++ code in `my_application.cc`.
* Reduced `example/linux/runner/my_application.cc` and `bin/setup.dart` template to a minimal ~180-line GTK/CSD/RGBA window shell.
* Added `AdwPortal.runCommand` (`GSubprocessLauncher`, normal and detached modes) alongside `AdwPortal.requestAdminAuthorization` and `AdwPortal.runElevated` (`pkexec`).
* Added a dedicated Linux-only **Polkit (Superuser)** demo page in `Adwaitter Demo` to test Polkit authorization, unprivileged commands, detached launches, and `pkexec`.

## 1.0.0-alpha.2

* Added native Linux GTK3/Cairo/Pango touch text magnifier popup bridge (`updateMagnifier` / `hideMagnifier`) so `100×60` @ `2.0×` magnifier popovers extend cleanly above the window edge without stealing focus.
* Added Linux system tray (`AdwSystemTray`), external drag-and-drop (`AdwDragDrop`), and native emoji font loading / picker bridges in `my_application.cc` and `dart run libadwaitter:setup`.
* Updated `Adwaitter Demo` sidebar search bar to `TextFieldTapRegion` for seamless touch selection toolbar interactions.

## 1.0.0-alpha

* Initial pre-alpha release of **Libadwaitter**, the GNOME Libadwaita 1.10+ suite for Flutter on Linux (Wayland/X11) and cross-platform UI via `adwaitter`.
* Added Linux GTK3 runner integration (`dart run libadwaitter:setup`): frameless CSD window management, drag/resize edges, minimize/maximize/fullscreen, native multi-window (`AdwSubWindow`), and 9-slice CSD drop shadows with `gdk_window_set_shadow_width`.
* Added `AdwPortal` native bridge for XDG Desktop Portals (`openUri`, `sendNotification`, `withdrawNotification`, `openFiles`, `saveFile`, `requestBackground`, `requestCamera`, `takeScreenshot`, `inhibit`, `uninhibit`, `getSandboxInfo`) with Android `openUri` support.
* Re-exports the complete `adwaitter` widget catalog and design system.
