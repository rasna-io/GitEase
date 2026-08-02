import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CheckboxItem
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property     string            title:       ""

    property     string            description: ""

    property     alias             checked:     swt.checked

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true
        
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }
        
        Text {
            Layout.fillWidth: true
            text: root.description
            font.family: Style.fontTypes.inter
            font.pixelSize: 10
            color: Style.colors.mutedText
        }
    }

    Switch {
        id: swt
        Layout.alignment: Qt.AlignVCenter
        padding: 0

        implicitWidth: 34
        implicitHeight: 20

        indicator: Rectangle {
            implicitWidth: 34
            implicitHeight: 20
            x: swt.leftPadding + (swt.availableWidth - width) / 2
            y: swt.topPadding + (swt.availableHeight - height) / 2
            radius: height / 2

            color: swt.checked ? Style.colors.accent : Style.colors.switchTrackOff
            border.width: swt.checked ? 0 : 1
            border.color: swt.hovered ? Style.colors.controlBorderHover
                                      : Style.colors.controlBorder

            Behavior on color       { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            Rectangle {
                id: handle
                width: 14
                height: 14
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: swt.checked ? parent.width - width - 3 : 3
                color: Style.colors.switchHandle
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.08)

                Behavior on x { NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
