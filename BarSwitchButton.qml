import QtQuick
import qs.Commons
import qs.Ui

// The logo button Taskbarchy puts at the left of the Omarchy bar. Left click
// swaps surfaces: the bar hides and the taskbar takes over. Right click keeps
// the old logo button's menu role and opens the root menu.
BarWidget {
  id: root
  moduleName: "xenobones.taskbarchy"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "omarchy"
    horizontalMargin: 7.5
    onPressed: function(mouseButton) {
      // This button only renders while the bar is mapped, so the toggle
      // deterministically hides it and brings the taskbar up.
      if (mouseButton === Qt.RightButton)
        Util.execDetached("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
      else
        Util.execDetached("omarchy toggle bar")
    }
  }
}
