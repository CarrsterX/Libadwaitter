# Libadwaitter Ecosystem Architecture & Development Guide

This document describes the 5-repository architecture of the **Libadwaitter** ecosystem, its strict separation of concerns, Git branching model, and implementation standards. It is designed so any developer or AI assistant can continue work on any of the libraries with full context.

---

## 1. Repository & Package Topology

All five projects are separate GitHub repositories with identical branch structure (`main`, `rc`, `beta`, `dev`). During local monorepo development, the four companion repositories live inside `packages/` (gitignored by the root `Libadwaitter` repository).

| Package / Repo | GitHub URL | Local Path | Platform Scope | Responsibility |
| :--- | :--- | :--- | :--- | :--- |
| **`Adwaitter`** (`adwaitter`) | `https://github.com/CarrsterX/Adwaitter` | `packages/adwaitter/` | Cross-platform (Android, iOS, Web, Linux, macOS, Windows) | Pure Flutter (`package:flutter/widgets.dart`) GNOME Adwaita UI widgets, `AdwTheme`, `AdwColors` / `AdwColorScheme`, `AdwTypography` (`AdwaitaSans` & `AdwaitaMono`), `AdwScrollbar`, and spring physics. Zero Material/Cupertino imports and zero Linux-only dependencies. |
| **`Adwaitter_Icons`** (`adwaitter_icons`) | `https://github.com/CarrsterX/Adwaitter_Icons` | `packages/adwaitter_icons/` | Cross-platform | Official GNOME Adwaita symbolic icon suite (`AdwIcons`, `AdwaitaIcons.ttf`). Optional — developers using `Adwaitter` can freely use Material Icons, CupertinoIcons, or any icon pack. |
| **`Fluttpak`** (`fluttpak`) | `https://github.com/CarrsterX/Fluttpak` | `packages/fluttpak/` | Linux (Flatpak / XDG Portals) | Runtime permission & sandbox bridge (`AdwPortal` via `libadwaitter/portal` over `org.freedesktop.portal.*`) and Flatpak packaging generator (`.yml` manifest, `.desktop`, `.metainfo.xml`, `.svg`, `build-flatpak.sh` for `stable` and `beta` channels). |
| **`Snaptter`** (`snaptter`) | `https://github.com/CarrsterX/Snaptter` | `packages/snaptter/` | Linux (Snap) | Snap strict confinement environment detection (`SnaptterEnv`) and `snap/snapcraft.yaml` generator (`core24`, `gnome` extension, `strict` confinement, `stable` / `devel` grade). |
| **`Libadwaitter`** (`libadwaitter`) | `https://github.com/CarrsterX/Libadwaitter` | `.` (root) | Linux Desktop (GNOME / Wayland) | Master Linux suite re-exporting `adwaitter`, `fluttpak`, and `snaptter`, plus the native GTK3/Wayland runner bridges (`my_application.cc`), CLI setup orchestrator (`dart run libadwaitter:setup`), and the `Adwaitter Demo` app (`example/`). |

---

## 2. Git Branching Model (All 5 Repositories)

Every repository uses four branches:
- `dev` — Active daily development (default working branch).
- `beta` — Public beta / unstable testing releases.
- `rc` — Release candidates for final QA before stable.
- `main` — Production stable releases.

---

## 3. Strict Architectural Boundaries

1. **Zero `material.dart` in UI or Platform Packages**:
   - `adwaitter`, `adwaitter_icons`, `fluttpak`, `snaptter`, and `libadwaitter` must never import `package:flutter/material.dart`.
   - Use `package:flutter/widgets.dart`, `painting.dart`, `services.dart`, `foundation.dart`, etc.
2. **UI vs. Linux Integrations Decoupling**:
   - Widgets in `packages/adwaitter/` must **never** import `fluttpak`, `snaptter`, or Linux-specific platform channels.
   - Platform bridges (`AdwPortal`, `SnaptterEnv`) must degrade gracefully on non-Linux platforms (returning `AdwPortalStatus.unsupported` / `false` without throwing `MissingPluginException`).
3. **Optional Iconography**:
   - `adwaitter` has **zero** dependency on `adwaitter_icons`. Internal structural glyphs (window controls, chevrons, radios/checks, spin `+/-`, emblem) use pure `CustomPainter` or accept standard `IconData` / `Widget` parameters.
4. **Centralized Color Tokens**:
   - All widget colors must be resolved from `AdwTheme.of(context).colors` (`AdwColorScheme`) or `AdwColors` (`packages/adwaitter/lib/src/theme/`). Never hardcode inline hex colors inside widgets.
   - High-contrast mode will be implemented as a dedicated full theme in a later phase.
5. **1:1 Fidelity with Upstream GNOME Libadwaita 1.10**:
   - Reference upstream `.ui` and `.scss` files (upstream repo cloned at `/tmp/libadwaita-src` when available) and Libadwaita 1.10 docs (`https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.10/`).
   - No Floating Action Buttons (FABs) — GNOME HIG uses headerbar actions, centered `.pill` + `.suggested` buttons, or `AdwToolbarView` bottom bars.
   - The demo application is named **Adwaitter Demo** (distinct from official GNOME `Adwaita Demo`).

---

## 4. Native Linux / Wayland & Packaging Bridges

### C++ Runner Channels (`example/linux/runner/my_application.cc` & `bin/setup.dart`)
- **Wayland Identity**: `g_set_prgname(APPLICATION_ID)` and `g_set_application_name(...)` match the `xdg_toplevel` surface to `<app-id>.desktop` and its icon.
- **`libadwaitter/window`**: Frameless RGBA transparent window (`CAIRO_OPERATOR_CLEAR`, `gtk_window_set_decorated(FALSE)`), CSD drag/resize (`startDragging`, `beginResizeDrag`), `close`, `minimize`, `maximize`, `isMaximized`, `isActive`, `onWindowActiveChanged`.
- **`libadwaitter/settings`**: `enableAnimations`, `durationFactor`, `button-layout`.
- **`libadwaitter/style`**: System light/dark `color-scheme`, `accent-color`, and `high-contrast` via `GSettings` and `org.freedesktop.portal.Settings` D-Bus.
- **`libadwaitter/portal`**: `getSandboxInfo` (`isFlatpak`, `isSnap`, `isWayland`), `openUri`, `sendNotification`, `withdrawNotification`, `openFiles`, `saveFile` (`GtkFileChooserNative` auto-delegates to `org.freedesktop.portal.FileChooser`), `inhibit`/`uninhibit`, and async `GDBusConnection` portal requests (`requestBackground`, `requestCamera`, `takeScreenshot`).

### CLI Setup Generator (`dart run libadwaitter:setup`)
- Keeps native development (`flutter run -d linux`) working with zero packaging overhead.
- Supports optional distribution flags:
  - `--app-id <reverse.dns>` (updates `linux/CMakeLists.txt` `APPLICATION_ID`)
  - `--title <name>`, `--width <px>`, `--height <px>`, `--counter`
  - `--flatpak` (generates `linux/packaging/flatpak/` manifest, `.desktop`, `.metainfo.xml`, `.svg`, `build-flatpak.sh`)
  - `--snap` (generates `snap/snapcraft.yaml`)
  - `--all-packaging`
  - `--channel <stable|beta>`

---

## 5. Current Status & Next Work

- **Separation & Analysis**: All 5 repositories + `example/` pass `flutter analyze` with `No issues found!` and `0` `material.dart` imports.
- **Note on `pubspec.yaml`**: Root `Libadwaitter/pubspec.yaml` temporarily has `publish_to: 'none'` while using `path: packages/...` dependencies. Before publishing to `pub.dev`, remove `publish_to: 'none'` and switch to hosted versions.
- **Demo Views (`adwaita-1-demo`, 21 views total)**:
  - Completed for Beta review: `Welcome`, `Boxed Lists`.
  - Next up for 1:1 upstream comparison & polish: `Navigation View` and the remaining 18 views tracked in `COMPONENTS.md` (local).
