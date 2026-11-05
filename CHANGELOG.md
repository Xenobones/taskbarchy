# Changelog

Notable changes to Taskbarchy. This project is a fork of
[maximxmoroz.win11-dock](https://github.com/maximxmoroz/omarchy-windows-dock).

## [Unreleased]

## [0.1.3] - 2026-11-04

### Changed

- Pinned apps no longer own a fixed workspace by pin order. Each launch now
  takes the next workspace (from `workspaceBase`) that has no windows.
- Hiding the Omarchy bar now mirrors its whole right-hand section in the
  taskbar: the real bar widgets (tray, network, audio, bluetooth, power,
  monitors, agents, third-party widgets — whatever `shell.json` lists) render
  beside the clock with live status, and clicking one opens the same panel
  anchored above the taskbar. The previous hand-built wifi/sound/battery
  buttons are gone; `showBarTools` still gates the feature.

### Added

- `BarAdapter.qml` / `BarWidgetHost.qml`: a bar-host stand-in so the shell's
  own bar-widget components can render inside the taskbar.

## [0.1.2] - 2026-11-04

### Changed

- The Start button now defaults to the Omarchy logo (`startIcon: "omarchy"`)
  instead of the Windows logo. Existing settings files are unchanged.

## [0.1.1] - 2026-11-04

### Fixed

- Auto-hide no longer hides the bar as soon as you move the pointer off the
  bottom edge to click something. The window's input mask now expands with the
  revealed bar instead of staying stuck on the 2 px edge strip.
- The edge strip stays live while revealed, so the floating dock doesn't flap
  when the pointer rests on the screen edge beside it.

## [0.1.0] - 2026-11-04

### Added

- Windows 11 style taskbar/dock for the Omarchy shell: centered or
  left-aligned icons, running-app pills, hover previews, pinning and reordering.
- Start button with selectable icon (`windows`, `omarchy`, `arch`, `linux`,
  `grid`, or any icon/image path).
- Optional power button beside Start with Shut down / Restart.
- Fixed workspace per pinned app (`pinnedWorkspaces`, `workspaceBase`).
- Button on the right that shows/hides the Omarchy bar.
- Wifi, sound and battery buttons beside the clock while the Omarchy bar is
  hidden; each opens the same panel the bar button would.
- Full-width taskbar or floating dock, theme-following or Windows 11 colors,
  English and Russian menus.
