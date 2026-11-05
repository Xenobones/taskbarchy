# Changelog

Notable changes to Taskbarchy. This project is a fork of
[maximxmoroz.win11-dock](https://github.com/maximxmoroz/omarchy-windows-dock).

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
