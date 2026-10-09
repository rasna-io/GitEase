import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * ButtonItem
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property     string            title:       ""

    property     string            description: ""

    property     bool              busy:        false

    property     string            buttonTitle: "Click Me"

    property     real              buttonWidth: 0


    /* Signals
     * ****************************************************************************************/

    signal clicked()


    /* Children
     * ****************************************************************************************/
    spacing: 16

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.alignment: Qt.AlignTop

        Text {
            Layout.fillWidth: true
            text: root.title
            font.pointSize: Style.appFont.h4Pt
            color: Style.colors.foreground
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.pointSize: Style.appFont.secondaryPt
            color: Style.colors.mutedText
            wrapMode: Text.WordWrap
        }
    }

    Button {
        id: btn
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: root.buttonWidth > 0 ? root.buttonWidth : implicitWidth
        flat: true
        text: root.buttonTitle
        enabled: root.enabled
        opacity: enabled ? 1.0 : 0.6

        background: Rectangle {
            implicitHeight: 34
            radius: 5
            color: btn.hovered && btn.enabled
                   ? Style.colors.accent
                   : Style.colors.secondaryBackground
            border.color: Style.colors.accent
            border.width: 1
        }

        contentItem: RowLayout {
            spacing: 6

            BusyIndicator {
                visible: root.busy
                running: root.busy
                implicitWidth: 18
                implicitHeight: 18
                Material.accent: "#ffffff"
            }

            Text {
                text: root.buttonTitle
                font: btn.font
                color: btn.hovered && btn.enabled
                       ? "#ffffff" : Style.colors.foreground
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }
        }

        onClicked: root.clicked()
    }
}
