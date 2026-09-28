import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseOrganizationRulesPlugin

/*! ***********************************************************************************************
 * RuleImportPopup
 * Warns the user that importing will replace all existing rules for this repository.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property url pendingFile

    /* Signals
     * ****************************************************************************************/
    signal confirmed(url fileUrl)

    /* Object Properties
     * ****************************************************************************************/
    width: 420
    height: 236
    padding: 0

    contentItem: Rectangle {
        color: Style.colors.popupBackground
        radius: 10
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 20
                Layout.rightMargin: 16
                spacing: 8

                Text {
                    text: "Import Rules"
                    Layout.fillWidth: true
                    color: Style.colors.popupTitleText
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: Style.appFont.mediumPt
                }

                Text {
                    text: "\u00d7"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h2Pt
                    color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                    : Style.colors.popupCloseButton

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Body
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 20
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignTop
                    radius: 18
                    color: Style.colors.notificationWarning
                    border.width: 1
                    border.color: Style.colors.notificationWarningBorder

                    Text {
                        anchors.centerIn: parent
                        text: Style.icons.warning
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: Style.appFont.mediumPt
                        color: Style.colors.notificationWarningIcon
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: "Replace existing rules?"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                        font.weight: Font.DemiBold
                        color: Style.colors.pluginCardTitle
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "All rules for this repository will be replaced with the ones from the imported file. This cannot be undone."
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                        color: Style.colors.pluginCardDescription
                        wrapMode: Text.WordWrap
                        lineHeight: 1.2
                    }
                }
            }

            // Footer
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 56

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Style.colors.popupHeaderSeparator
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    RuleButton {
                        text: "Cancel"
                        onClicked: root.close()
                    }

                    RuleButton {
                        variant: "danger"
                        text: "Replace rules"
                        iconText: Style.icons.upload
                        onClicked: {
                            root.confirmed(root.pendingFile)
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
