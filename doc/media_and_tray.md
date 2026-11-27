# Media & System Tray

System media controller integration (MPRIS2 on Linux, `MediaSession` on Android,
Media Session API on Web) and Linux StatusNotifierItem / AppIndicator tray
icons.

## Key APIs

* `AdwMediaSession`, `AdwMediaMetadata`, `AdwMediaCommand`,
  `AdwPlaybackStatus`, & `AdwLoopMode` — Publish playback state and receive
  hardware/lock-screen media commands.
* `AdwSystemTray`, `AdwTrayMenuItem`, `AdwTrayEvent`, & `AdwTrayEventType` —
  Manage Linux desktop tray icons, context menus, and background-mode windows
  via pure GLib `GDBus`.
