import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

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
    property Item content
    property color ruleColor

    /* Object Properties
     * ****************************************************************************************/
    radius: 10
    color: Style.colors.pluginCardBackground
    border.width: 1
    border.color: Style.colors.pluginCardBorder
    Layout.preferredHeight: mainColumn.implicitHeight

    onContentChanged: {
        if (content) {
            content.parent = contentContainer
            content.anchors.left = contentContainer.left
            content.anchors.right = contentContainer.right
            content.anchors.top = contentContainer.top
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 14
                    Layout.alignment: Qt.AlignVCenter
                    color: root.ruleColor
                    radius: 2
                }

                Text {
                    text: root.headerText
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    font.weight: Font.DemiBold
                    color: Style.colors.pluginCardTitle
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.colors.pluginCardFooterBorder
        }

        // Content
        Item {
            id: contentContainer
            Layout.fillWidth: true
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.topMargin: 14
            Layout.bottomMargin: 16
            Layout.preferredHeight: root.content ? root.content.implicitHeight : 0
        }
    }
}
