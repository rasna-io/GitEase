import QtQuick
import QtQuick.Controls

/*! ***********************************************************************************************
 * PalettoButton
 * variant: "primary", "secondary", "ghost" or "danger".
 * ************************************************************************************************/
AbstractButton {
    id: root

    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    /* Property Declarations
     * ****************************************************************************************/
    property string variant:  "secondary"
    property string iconText: ""
    property string tooltip:  ""

    readonly property bool primary: variant === "primary"
    readonly property bool ghost:   variant === "ghost"
    readonly property bool danger:  variant === "danger"

    readonly property color labelColor: primary ? root.chrome.accentText
                                      : danger  ? root.chrome.danger
                                                : root.chrome.text

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 30
    implicitWidth: buttonRow.implicitWidth + 20
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.4
    scale: down ? 0.97 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 90
            easing.type: Easing.OutCubic
        }
    }

    PalettoToolTip {
        visible: root.hovered && root.tooltip.length > 0
        text: root.tooltip
    }

    background: Rectangle {
        radius: 7
        color: root.primary ? (root.hovered ? root.chrome.accentHover : root.chrome.accent)
             : root.ghost   ? (root.hovered ? root.chrome.rowHover : "transparent")
                            : (root.hovered ? root.chrome.borderStrong : root.chrome.panelRaised)
        border.width: root.primary || root.ghost ? 0 : 1
        border.color: root.danger && root.hovered ? root.chrome.danger : root.chrome.border

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }
    }

    contentItem: Item {
        Row {
            id: buttonRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.iconText.length > 0
                text: root.iconText
                font.family: root.chrome.fontIcons
                font.pixelSize: root.chrome.sizeCaption
                color: root.labelColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.text.length > 0
                text: root.text
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeCaption
                font.weight: root.primary ? Font.DemiBold : Font.Medium
                color: root.labelColor
            }
        }
    }

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
