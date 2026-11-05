# Changelog

Notable changes to Taskbarchy. This project is a fork of
[maximxmoroz.win11-dock](https://github.com/maximxmoroz/omarchy-windows-dock).

## [Unreleased]

## [0.1.5] - 2026-11-05

### Added

- The power button menu now offers Suspend, Hibernate and Lock alongside
  Shut down and Restart, with the same gating the Omarchy root menu uses:
  Hibernate appears only when hibernation is set up, and Suspend disappears
  when suspended has been turned off in the system menu. Availability is
  re-checked every time the menu opens.
- Docs: a "Setting up a new machine" checklist in the README.

## [0.1.4] - 2026-11-05

### Changed

- The taskbar and the Omarchy bar are now mutually exclusive: hiding the bar
  (any way you do it) raises the taskbar, and showing it lowers the taskbar.
  The old both-visible coexistence is gone.
- The taskbar's right-side button now switches surfaces: it shows the Omarchy
  bar and the taskbar hides itself.

### Added

- A bar widget (`BarSwitchButton.qml`, registered as `Xenobones.taskbarchy`):
  the Omarchy logo for the bar's left section. Left-click hides the bar and
  raises the taskbar; right-click opens the root menu, keeping the old menu
  button's role. Add it with
  `omarchy bar put Xenobones.taskbarchy --section left --index 0`.

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
