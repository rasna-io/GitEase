import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase

Rectangle {
    id: root
    /* Property Declarations
     * ****************************************************************************************/
    property bool isMinimized: false

    /* Signals
     * ****************************************************************************************/
    signal minimizeRequested();
    signal expandRequested();

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.secondaryBackground

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Label {
            text: "Terminal"
            color: Style.colors.foreground
            font.family: Style.fontTypes.roboto
            font.weight: 500
            font.pixelSize: 10
            Layout.fillWidth: true
        }

        ActionIconButton {
            width: 20
            height: 20
            iconText: root.isMinimized ? "⌃" : "⌄"
            onClicked: {
                if (root.isMinimized) {
                    root.expandRequested()
                } else {
                    root.minimizeRequested()
                }
            }
        }
    }

    Rectangle {
        visible: !root.isMinimized
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#333333"
    }
}
