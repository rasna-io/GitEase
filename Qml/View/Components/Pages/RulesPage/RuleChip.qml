import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * RuleChip
 * Displays a rule configuration section with a header and dynamic content.
 * The content area is populated using a Loader with the provided component.
 */

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property string headerText
    property Component content
    property color ruleColor

    /* Object Properties
     * ****************************************************************************************/
    radius: 5
    color: "transparent"
    border.width: 1
    border.color: Style.colors.secondaryBackground
    Layout.preferredHeight: mainColumn.implicitHeight + 5

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: mainColumn
        anchors.fill: parent

        // Header rect
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            radius: 5
            color: Style.colors.secondaryBackground

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 15
                    color: root.ruleColor
                    radius: 5
                }

                Text {
                    text: root.headerText
                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true
                    font.pixelSize: 13
                    color: Style.colors.placeholderText
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // Content
        Loader {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            sourceComponent: root.content
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
