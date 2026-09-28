import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SegmentedSelector
 * Pill-style single choice selector. Model items: { text, color }.
 * The selected segment is tinted with its own color so severities read at a glance.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var model: []
    property int currentIndex: 0

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: segmentsRow.implicitWidth + 6
    implicitHeight: 32
    radius: 8
    color: Style.colors.utilitiesSegmentTrackBackground
    border.width: 1
    border.color: Style.colors.utilitiesSegmentTrackBorder

    /* Children
     * ****************************************************************************************/
    Row {
        id: segmentsRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: segment

                readonly property bool isSelected: root.currentIndex === index
                readonly property color tone: modelData.color

                width: Math.max(64, segmentLabel.implicitWidth + 30)
                height: root.height - 6
                radius: 6
                color: isSelected ? Qt.rgba(tone.r, tone.g, tone.b, 0.14)
                                  : (segmentHover.containsMouse ? Style.colors.utilitiesSegmentHoverBackground
                                                                : "transparent")
                border.width: isSelected ? 1 : 0
                border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.55)

                Behavior on color { ColorAnimation { duration: Style.motionFast; easing.type: Easing.OutCubic } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: segment.tone
                        opacity: segment.isSelected ? 1.0 : 0.55
                    }

                    Text {
                        id: segmentLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                        font.weight: segment.isSelected ? Font.DemiBold : Font.Normal
                        color: segment.isSelected ? segment.tone : Style.colors.utilitiesSegmentText
                    }
                }

                MouseArea {
                    id: segmentHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentIndex = index
                }
            }
        }
    }
}
