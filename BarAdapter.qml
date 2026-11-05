import QtQuick
import qs.Commons

// Stand-in for the Omarchy bar host. Real bar widgets expect a `bar` object
// with the presentation properties and coordination methods below; this lets
// the taskbar render those widgets while the top bar is hidden.
QtObject {
  id: root

  required property var dock

  property var shell: dock.shell
  property var layoutConfig: dock.shell && dock.shell.barConfig && dock.shell.barConfig.layout
    ? dock.shell.barConfig.layout
    : ({ left: [], center: [], right: [] })

  property color foreground: dock.text
  property color barForeground: dock.text
  property color background: dock.surface
  property color urgent: dock.urgent
  property string fontFamily: dock.config ? dock.config.fontFamily : ""
  property string position: "bottom"
  property bool vertical: false
  property int barSize: Style.bar.sizeHorizontal
  property bool transparent: dock.config ? dock.config.transparent : false
  property bool foregroundAnimationEnabled: true
  property bool centerSectionRevealHeld: false
  property bool _centerHoverRevealSuppressed: false
  readonly property bool centerHoverRevealSuppressed: _centerHoverRevealSuppressed
  property var activePopout: null
  property var clickTargets: []
  readonly property var foreignPopoutMarker: ({ foreign: true })

  // The taskbar's widget hosts, used to answer moduleWidgets() so widgets can
  // broadcast changes to their peers.
  property var hosts: []

  function showTooltip(target, text) {}
  function hideTooltip(target) {}

  function registerClickTarget(target) {
    if (!target || clickTargets.indexOf(target) !== -1) return
    var next = clickTargets.slice()
    next.push(target)
    clickTargets = next
  }

  function unregisterClickTarget(target) {
    var at = clickTargets.indexOf(target)
    if (at < 0) return
    var next = clickTargets.slice()
    next.splice(at, 1)
    clickTargets = next
  }

  function requestPopout(owner) {
    if (activePopout === owner) return
    if (activePopout) {
      if ("closeForPopoutSwitch" in activePopout) activePopout.closeForPopoutSwitch()
      else if ("close" in activePopout) activePopout.close()
    }
    activePopout = owner
  }

  function releasePopout(owner) {
    if (activePopout === owner) activePopout = null
  }

  function switchPanelFrom(owner, direction) {
    return false
  }

  function targetBelongsToWindow(target, window) {
    return !!target && !!window && !!target.QsWindow && target.QsWindow.window === window
  }

  function registerHost(host) {
    if (!host || hosts.indexOf(host) !== -1) return
    var next = hosts.slice()
    next.push(host)
    hosts = next
  }

  function unregisterHost(host) {
    var at = hosts.indexOf(host)
    if (at < 0) return
    var next = hosts.slice()
    next.splice(at, 1)
    hosts = next
  }

  function moduleWidgets(id) {
    var out = []
    for (var i = 0; i < hosts.length; i++) {
      var host = hosts[i]
      if (host && host.entry && host.entry.id === id && host.impl) out.push(host.impl)
    }
    return out
  }

  function run(command) {
    if (command) Util.execDetached(String(command))
  }

  function setCenterHoverRevealSuppressed(value) {
    _centerHoverRevealSuppressed = !!value
  }
}
