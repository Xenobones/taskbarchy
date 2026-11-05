import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.Commons

// Entry point. Owns the config file, the palette and the app model; one
// Taskbar window per screen renders from it.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property var pluginRegistry: null

  readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy/win11-dock.json"

  // ---- Config ------------------------------------------------------------

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    // First run: materialize the defaults so the file is there to edit.
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) writeAdapter()
    }

    JsonAdapter {
      id: config
      // Desktop entry ids (without ".desktop"), left to right.
      property list<string> pinned: []
      // Each pinned app owns a workspace: the first pin opens on
      // workspaceBase, the next on workspaceBase + 1, and so on.
      property bool pinnedWorkspaces: true
      property int workspaceBase: 1
      property bool floating: false
      property bool autoHide: false
      // "center" or "left"
      property string alignment: "center"
      // "theme" follows the Omarchy theme; "dark" / "light" use Windows 11 colors.
      property string colorScheme: "theme"
      property int barHeight: 48
      property int iconSize: 26
      property real opacity: 0.9
      // No background and no edge line: just the icons over the wallpaper.
      property bool transparent: false
      property bool showStart: true
      property string startCommand: "omarchy-menu toggle apps"
      // One of startIcons, or an icon name / absolute image path.
      property string startIcon: "windows"
      // Shut down / restart button beside Start.
      property bool showPower: true
      property bool showClock: true
      property bool showPreviews: true
      // Button on the right of the dock that shows/hides the Omarchy bar.
      property bool showBarToggle: true
      // Battery, sound and wifi buttons shown while the Omarchy bar is hidden.
      property bool showBarTools: true
      property string fontFamily: "sans-serif"
    }
  }

  readonly property alias config: config

  // Built-in Start icons. The glyph ones come from fonts Omarchy ships: its
  // own logo font, and the Nerd Font behind the "monospace" alias.
  readonly property var startIcons: ["windows", "omarchy", "arch", "linux", "grid"]
  readonly property var startGlyphs: ({
    omarchy: { text: "\ue900", font: "omarchy" },
    arch: { text: "\uf303", font: "monospace" },
    linux: { text: "\uf17c", font: "monospace" }
  })

  // ---- Metrics -----------------------------------------------------------

  readonly property int barHeight: Math.max(32, config.barHeight)
  readonly property int buttonSize: barHeight - 8
  readonly property int iconSize: Math.min(config.iconSize, buttonSize - 8)
  readonly property bool floating: config.floating
  readonly property bool autoHide: config.autoHide
  readonly property int floatMargin: floating ? 8 : 0

  // ---- Palette -----------------------------------------------------------

  readonly property bool themed: config.colorScheme !== "dark" && config.colorScheme !== "light"
  readonly property bool dark: themed ? Color.background.hslLightness < 0.5 : config.colorScheme === "dark"
  readonly property color surface: themed ? Color.background : (dark ? "#202020" : "#f3f3f3")
  readonly property color text: themed ? Color.foreground : (dark ? "#ffffff" : "#1b1b1b")
  readonly property color accent: themed ? Color.accent : (dark ? "#4cc2ff" : "#0067c0")
  readonly property color urgent: themed ? Color.urgent : "#c42b1c"
  readonly property color barColor: config.transparent ? "transparent" : Util.alpha(surface, Util.clampAlpha(config.opacity))
  readonly property color popupColor: Qt.rgba(surface.r, surface.g, surface.b, 1)
  readonly property color stroke: Util.alpha(text, dark ? 0.1 : 0.14)

  // ---- App model ---------------------------------------------------------

  // appModel carries only the ordered keys so delegates survive window
  // open/close; the per-app data lives in appData and is looked up by key.
  ListModel { id: appModel }
  readonly property alias appModel: appModel
  property var appData: ({})

  function lookupEntry(id) {
    if (!id) return null
    return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id)
  }

  function rebuild() {
    var data = {}
    var order = []
    var pinned = config.pinned

    for (var i = 0; i < pinned.length; i++) {
      var pinEntry = lookupEntry(pinned[i])
      var pinKey = (pinEntry ? pinEntry.id : pinned[i]).toLowerCase()
      if (data[pinKey]) continue
      data[pinKey] = { key: pinKey, pinId: pinned[i], appId: pinned[i], entry: pinEntry, pinned: true, windows: [] }
      order.push(pinKey)
    }

    var toplevels = ToplevelManager.toplevels.values
    for (var j = 0; j < toplevels.length; j++) {
      var toplevel = toplevels[j]
      var appId = toplevel.appId
      if (!appId) continue
      var entry = lookupEntry(appId)
      var key = (entry ? entry.id : appId).toLowerCase()
      if (!data[key]) {
        data[key] = { key: key, pinId: entry ? entry.id : appId, appId: appId, entry: entry, pinned: false, windows: [] }
        order.push(key)
      }
      data[key].windows.push(toplevel)
    }

    appData = data
    syncModel(order)
  }

  // Minimal diff so unchanged buttons keep their delegate (and animations).
  function syncModel(order) {
    for (var i = appModel.count - 1; i >= 0; i--) {
      if (order.indexOf(appModel.get(i).key) < 0) appModel.remove(i)
    }
    for (var j = 0; j < order.length; j++) {
      if (j < appModel.count && appModel.get(j).key === order[j]) continue
      var at = -1
      for (var k = j + 1; k < appModel.count; k++) {
        if (appModel.get(k).key === order[j]) { at = k; break }
      }
      if (at >= 0) appModel.move(at, j, 1)
      else appModel.insert(j, { key: order[j] })
    }
  }

  function scheduleRebuild() { Qt.callLater(rebuild) }

  Component.onCompleted: rebuild()

  Connections {
    target: config
    function onPinnedChanged() { root.scheduleRebuild() }
  }

  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() { root.scheduleRebuild() }
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() { root.scheduleRebuild() }
  }

  // A toplevel usually announces its appId a moment after it appears.
  Instantiator {
    model: ToplevelManager.toplevels
    delegate: Connections {
      required property var modelData
      target: modelData
      function onAppIdChanged() { root.scheduleRebuild() }
    }
  }

  // ---- Icon theme --------------------------------------------------------

  // Icon URLs don't change when the system icon theme does, so images would
  // keep showing the old theme. Buttons reload when this ticks.
  property int iconRevision: 0

  Process {
    running: true
    command: ["gsettings", "monitor", "org.gnome.desktop.interface", "icon-theme"]
    stdout: SplitParser {
      onRead: iconReload.restart()
    }
  }

  // Gives Qt a moment to switch themes before the icons are requested again.
  Timer {
    id: iconReload
    interval: 600
    onTriggered: root.iconRevision++
  }

  // ---- Actions -----------------------------------------------------------

  function appName(info) {
    if (!info) return ""
    return info.entry ? info.entry.name : info.appId
  }

  function iconFor(info) {
    var name = info && info.entry ? info.entry.icon : (info ? info.appId : "")
    if (!name) return Quickshell.iconPath("application-x-executable")
    if (name.charAt(0) === "/") return Util.fileUrl(name)
    return Quickshell.iconPath(name, "application-x-executable")
  }

  // Workspace a pinned app owns, or 0 when disabled / the app isn't pinned.
  function workspaceFor(info) {
    if (!info || !config.pinnedWorkspaces) return 0
    var at = pinIndex(info)
    if (at < 0) return 0
    return Math.max(1, config.workspaceBase) + at
  }

  // Hyprland 0.5x runs Lua dispatchers; older configs use the plain syntax.
  function focusWorkspace(workspace) {
    if (Hyprland.usingLua) Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + workspace + "\" })")
    else Hyprland.dispatch("workspace " + workspace)
  }

  function launch(info) {
    if (!info) return
    var workspace = workspaceFor(info)
    if (workspace > 0) focusWorkspace(workspace)
    if (info.entry) Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", info.entry.id + ".desktop"])
    else Quickshell.execDetached(["uwsm-app", "--", info.appId])
  }

  // Left click: launch when not running, otherwise focus the app; clicking
  // the already focused app steps through its windows.
  function activate(info) {
    if (!info) return
    var windows = info.windows
    if (windows.length === 0) {
      launch(info)
      return
    }
    for (var i = 0; i < windows.length; i++) {
      if (windows[i].activated) {
        if (windows.length > 1) windows[(i + 1) % windows.length].activate()
        return
      }
    }
    windows[0].activate()
  }

  function closeAll(info) {
    if (!info) return
    var windows = info.windows.slice()
    for (var i = 0; i < windows.length; i++) windows[i].close()
  }

  function pinIndex(info) {
    if (!info) return -1
    var pinned = config.pinned
    for (var i = 0; i < pinned.length; i++) {
      if (pinned[i] === info.pinId) return i
    }
    return -1
  }

  function pin(info) {
    if (!info || pinIndex(info) >= 0) return
    var pinned = Array.from(config.pinned)
    pinned.push(info.pinId)
    config.pinned = pinned
  }

  function unpin(info) {
    var at = pinIndex(info)
    if (at < 0) return
    var pinned = Array.from(config.pinned)
    pinned.splice(at, 1)
    config.pinned = pinned
  }

  function movePin(info, delta) {
    var at = pinIndex(info)
    var to = at + delta
    if (at < 0 || to < 0 || to >= config.pinned.length) return
    var pinned = Array.from(config.pinned)
    pinned.splice(to, 0, pinned.splice(at, 1)[0])
    config.pinned = pinned
  }

  // Drag reordering works on the model alone, so the dragged delegate stays
  // alive; the new order is written to the config once, on drop.
  function pinnedCount() {
    var count = 0
    for (var i = 0; i < appModel.count; i++) {
      var info = appData[appModel.get(i).key]
      if (info && info.pinned) count++
    }
    return count
  }

  function moveApp(from, to) {
    if (from !== to) appModel.move(from, to, 1)
  }

  function commitOrder() {
    var pinned = []
    for (var i = 0; i < appModel.count; i++) {
      var info = appData[appModel.get(i).key]
      if (info && info.pinned) pinned.push(info.pinId)
    }
    config.pinned = pinned
  }

  function runStart() {
    if (config.startCommand) Quickshell.execDetached(["sh", "-c", config.startCommand])
  }

  function shutdown() {
    Quickshell.execDetached(["omarchy", "system", "shutdown"])
  }

  function reboot() {
    Quickshell.execDetached(["omarchy", "system", "reboot"])
  }

  // ---- Omarchy bar visibility --------------------------------------------

  // `omarchy toggle bar` flips this flag file; its presence means the bar is
  // hidden. The parent directory is watched because FileView cannot observe a
  // file that does not exist yet.
  readonly property string togglesPath: Quickshell.env("HOME") + "/.local/state/omarchy/toggles"
  property bool barHidden: false

  Process {
    id: barProbe
    running: true
    command: ["bash", "-c", "[[ -f $HOME/.local/state/omarchy/toggles/bar-off ]] && echo yes || echo no"]
    stdout: SplitParser {
      onRead: function(line) { root.barHidden = String(line).trim() === "yes" }
    }
  }

  FileView {
    path: root.togglesPath
    watchChanges: true
    printErrors: false
    onFileChanged: barProbe.running = true
  }

  // Covers rapid toggles, where the directory watch can miss the change.
  Timer {
    id: barProbeDelay
    interval: 250
    onTriggered: barProbe.running = true
  }

  function toggleBar() {
    Quickshell.execDetached(["omarchy", "toggle", "bar"])
    barProbeDelay.restart()
  }

  // ---- Omarchy quick settings --------------------------------------------

  // The shell's audio, network and power panels answer to their own IPC
  // targets, so the dock can open the very panels the bar buttons would,
  // even while the bar itself is hidden.
  function toggleOmarchyPanel(target) {
    Quickshell.execDetached(["omarchy-shell", target, "toggle"])
  }

  // Live state for the tool buttons; the services are singletons and these
  // bindings refresh on their own.
  readonly property var audioSink: Pipewire.defaultAudioSink
  readonly property bool audioMuted: !!(audioSink && audioSink.muted)
  readonly property int audioVolume: audioSink ? Math.round(audioSink.volume * 100) : 0

  readonly property var batteryDevice: UPower.displayDevice
  readonly property bool batteryPresent: !!(batteryDevice && batteryDevice.isPresent)
  readonly property real batteryFraction: batteryPresent
    ? Util.clamp(batteryDevice.percentage / 100, 0, 1) : 0
  readonly property bool batteryCharging: batteryPresent
    && batteryDevice.state === UPowerDeviceState.Charging

  // Prefer a connected wifi device; fall back to the first one so the state
  // still reads sensibly while connecting.
  readonly property var wifiDevice: {
    var devices = Networking.devices ? Networking.devices.values : []
    var fallback = null
    for (var i = 0; i < devices.length; i++) {
      var device = devices[i]
      if (!device || device.type !== DeviceType.Wifi) continue
      if (device.connected) return device
      if (!fallback) fallback = device
    }
    return fallback
  }
  readonly property bool wifiConnected: !!(wifiDevice && wifiDevice.connected)

  // ---- IPC ---------------------------------------------------------------

  // omarchy-shell win11-dock <function> [args], e.g. for Hyprland keybinds.
  IpcHandler {
    target: "win11-dock"

    function toggleAutoHide(): void { config.autoHide = !config.autoHide }
    function toggleFloating(): void { config.floating = !config.floating }
    function pin(id: string): void {
      if (config.pinned.indexOf(id) >= 0) return
      var pinned = Array.from(config.pinned)
      pinned.push(id)
      config.pinned = pinned
    }
    function unpin(id: string): void {
      config.pinned = Array.from(config.pinned).filter(function(pin) { return pin !== id })
    }
  }

  // ---- Windows -----------------------------------------------------------

  Variants {
    model: Quickshell.screens

    Taskbar {
      dock: root
    }
  }
}
