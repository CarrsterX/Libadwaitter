/// Pure Dart & Flutter suite for GNOME Libadwaita on Linux, Android, and Web.
///
/// Re-exports the complete `package:adwaitter/adwaitter.dart` UI widget and
/// design system library and adds native OS integration bridges:
///
/// * **Desktop Portals** ([AdwPortal]): XDG Desktop Portals, notifications,
///   sandbox detection, and Polkit command execution.
/// * **Drag & Drop** ([AdwDragAndDrop], [AdwDropTarget], [AdwDragSource]):
///   External file/text drag-and-drop across Linux GTK3, Android, and Web.
/// * **Media Session** ([AdwMediaSession]): MPRIS2 (Linux), Android
///   `MediaSession`, and Web Media Session API integration.
/// * **System Tray** ([AdwSystemTray]): Linux StatusNotifierItem /
///   AppIndicator tray icon and background-mode window support.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter/widgets.dart';
/// import 'package:libadwaitter/libadwaitter.dart';
///
/// void main() {
///   runApp(
///     const AdwApplication(
///       title: 'My GNOME App',
///       home: AdwWindow(
///         headerBar: AdwHeaderBar(
///           titleWidget: AdwWindowTitle(title: 'My GNOME App'),
///         ),
///         child: AdwStatusPage(title: Text('Welcome')),
///       ),
///     ),
///   );
/// }
/// ```
library libadwaitter;

export 'package:adwaitter/adwaitter.dart';
export 'src/adw_drag_drop.dart';
export 'src/adw_media_session.dart';
export 'src/adw_portal.dart';
export 'src/adw_system_tray.dart';

/// No-op Dart plugin registration for Android, Linux, and Web.
class LibadwaitterDartPlugin {
  /// Registers the pure-Dart side of the `libadwaitter` plugin.
  static void registerWith([Object? registrar]) {}
}
