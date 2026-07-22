import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * UpdateCard
 * Compact application-update panel used inside the Settings → Updates tab. Shows the installed and
 * latest versions, a check/update action, and the current update status.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property UpdateController updateController: null

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: content.implicitHeight + 32
    radius: 10
    color: Style.colors.controlBackground
    border.width: 1
    border.color: Style.colors.controlBorder

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 36

            ColumnLayout {
                spacing: 4

                Text {
                    text: "INSTALLED"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    color: Style.colors.mutedText
                }

                Text {
                    text: Qt.application.version || "0.0.0"
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Style.colors.foreground
                }
            }

            ColumnLayout {
                spacing: 4

                Text {
                    text: "LATEST"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    color: Style.colors.mutedText
                }

                Text {
                    text: (root.updateController?.latestVersion ?? "") !== ""
                          ? root.updateController.latestVersion
                          : "—"
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: root.updateController?.updateAvailable === true
                           ? Style.colors.accent : Style.colors.foreground
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                id: installUpdateButton
                visible: root.updateController?.updateAvailable === true
                Layout.alignment: Qt.AlignVCenter
                flat: true
                implicitHeight: 34
                leftPadding: 16
                rightPadding: 16
                topPadding: 0
                bottomPadding: 0
                topInset: 0
                bottomInset: 0
                enabled: root.updateController !== null
                         && root.updateController.updateAvailable
                         && !(root.updateController?.busy ?? false)

                background: Rectangle {
                    implicitHeight: 34
                    radius: 6
                    color: installUpdateButton.hovered ? Style.colors.accentHover
                                                        : Style.colors.accent
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                contentItem: Text {
                    text: root.updateController?.busy ? "Updating…" : "Update"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 12
                    color: Style.colors.onAccentText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (root.updateController)
                        root.updateController.installAvailableUpdate()
                }
            }

            Button {
                id: checkUpdatesButton
                Layout.alignment: Qt.AlignVCenter
                flat: true
                implicitHeight: 34
                leftPadding: 16
                rightPadding: 16
                topPadding: 0
                bottomPadding: 0
                topInset: 0
                bottomInset: 0
                enabled: root.updateController !== null
                         && !(root.updateController?.busy ?? false)

                background: Rectangle {
                    implicitHeight: 34
                    radius: 6
                    color: Style.colors.controlBackgroundHover
                    border.width: 1
                    border.color: checkUpdatesButton.hovered && checkUpdatesButton.enabled
                                  ? Style.colors.accent
                                  : Style.colors.controlBorder
                    Behavior on color        {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                contentItem: RowLayout {
                    spacing: 6

                    BusyIndicator {
                        visible: root.updateController?.busy ?? false
                        running: root.updateController?.busy ?? false
                        implicitWidth: 16
                        implicitHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Material.accent: Style.colors.accent
                    }

                    Text {
                        text: root.updateController?.busy ? "Checking…" : "Check for Updates"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 12
                        color: Style.colors.foreground
                        Layout.alignment: Qt.AlignVCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onClicked: {
                    if (root.updateController)
                        root.updateController.checkForUpdates()
                }
            }
        }

        RowLayout {
            id: updateStatusRow
            Layout.fillWidth: true
            spacing: 8

            readonly property color statusColor: {
                switch (root.updateController?.statusType) {
                    case "success":
                        return Style.colors.notificationSuccessIcon
                    case "warning":
                        return Style.colors.notificationWarningIcon
                    case "error":
                        return Style.colors.notificationErrorIcon
                    default:
                        return Style.colors.mutedText
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 8
                height: 8
                radius: 4
                color: updateStatusRow.statusColor
            }

            Text {
                Layout.fillWidth: true
                text: root.updateController?.statusText ?? "Not checked yet"
                font.family: Style.fontTypes.inter
                font.pixelSize: 12
                color: updateStatusRow.statusColor
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
