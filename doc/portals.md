# Desktop Portals

Native XDG Desktop Portal and OS integration APIs exposed via `AdwPortal`.

All portal helpers are designed to degrade safely across platforms — returning
`AdwPortalStatus.unsupported` (or safe fallbacks on Web/Android) when a feature
is unavailable on the host OS.

## Capabilities

* **Notifications**: Send interactive desktop/mobile notifications with action
  buttons (`AdwPortal.sendNotification`, `AdwNotificationAction`,
  `AdwNotificationEvent`).
* **File & URI Operations**: Open files, save dialogs, pickers, and external
  URLs via XDG portals.
* **Sandbox & System Info**: Detect Flatpak, Snap, and Wayland environments
  (`AdwSandboxInfo`).
* **Commands & Polkit Elevation**: Execute host commands and elevated Polkit
  actions on Linux (`AdwCommandResult`).
