import QtQuick

// Renders one real Omarchy bar widget inside the taskbar. The component comes
// from the bar-widget catalogue; `bar` is a BarAdapter standing in for the
// hidden top bar.
Item {
  id: host

  required property var dock

  // Filled by the Repeater: one layout entry from the bar's right section.
  required property var modelData
  readonly property var entry: modelData

  readonly property var impl: loader.item
  readonly property bool shown: dock.config.showBarTools && dock.barHidden && !dock.floating
  visible: shown
  width: shown && impl ? impl.implicitWidth : 0
  height: shown && impl ? impl.implicitHeight : 0

  Component.onCompleted: dock.barAdapter.registerHost(host)
  Component.onDestruction: dock.barAdapter.unregisterHost(host)

  Loader {
    id: loader
    anchors.fill: parent
    active: host.shown
    sourceComponent: host.entry ? host.entry.component : null

    onLoaded: {
      if (!item) return
      item.moduleName = host.entry.id
      item.settings = host.entry.settings || ({})
      item.bar = host.dock.barAdapter
    }
  }
}
