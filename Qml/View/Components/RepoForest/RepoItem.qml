import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoItem
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property       int     index
    required property       var     modelData
    property                bool    isSelected: false
    property                bool    isProcessing: false
    readonly property       bool    patNeeded:  root.modelData.status === "PAT waiting"
    property                string  pat:        ""

    /* Signals
     * ****************************************************************************************/
    signal clicked(index: int)
    signal fetchRequested(index: int, pat: string)
    signal pullRequested(index: int, pat: string)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: root.patNeeded ? 120 : 70
    color: {
        if (msa.hovered) {
                return Qt.darker(Style.colors.surfaceLight, 1.05)
        } else {
            if (isSelected)
                return Style.colors.repoSelectectedItem
            else
                return Style.colors.secondaryBackground
        }
    }
    radius: 3

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        spacing: 5

        Rectangle {
            Layout.preferredWidth: 3
            Layout.fillHeight: true
            Layout.margins: 7
            radius: 100
            color: root.isSelected ? Style.colors.accent : Style.colors.disabledButton
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 15
            Layout.topMargin: 5
            Layout.rightMargin: 15
            Layout.bottomMargin: 5
            spacing: 5

            // Name row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ScrollingText {
                    Layout.fillWidth: true
                    text: root.modelData.name
                    font.pixelSize: 12
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.letterSpacing: 0
                    color: Style.colors.foreground
                }

                Rectangle {
                    id: status

                    property int progress: root.modelData.progress || -1

                    property color statusTextColor: {
                        switch(root.modelData.status) {
                            case "Canceled":
                                return Style.colors.repoItemStatusCanceledText
                            case "Pending":
                                return Style.colors.repoItemStatusPendingText
                            case "Fetching":
                                return Style.colors.repoItemStatusFetchingText
                            case "Pulling":
                                return Style.colors.repoItemStatusPullingText
                            case "Done":
                                return Style.colors.repoItemStatusDoneText
                            case "Dirty":
                                return Style.colors.repoItemStatusDirtyText
                            case "Conflict":
                                return Style.colors.repoItemStatusConflictText
                            case "PAT waiting":
                                return Style.colors.repoItemStatusPATText
                            default:
                                return Style.colors.repoItemStatusPendingText
                        }
                    }

                    property color statusBgColor: {
                        switch(root.modelData.status) {
                            case "Canceled":
                                return Style.colors.repoItemStatusCanceledBg
                            case "Pending":
                                return Style.colors.repoItemStatusPendingBg
                            case "Fetching":
                                return Style.colors.repoItemStatusFetchingBg
                            case "Pulling":
                                return Style.colors.repoItemStatusPullingBg
                            case "Done":
                                return Style.colors.repoItemStatusDoneBg
                            case "Dirty":
                                return Style.colors.repoItemStatusDirtyBg
                            case "Conflict":
                                return Style.colors.repoItemStatusConflictBg
                            case "PAT waiting":
                                return Style.colors.repoItemStatusPATBg
                            default:
                                return Style.colors.repoItemStatusPendingBg
                        }
                    }

                    property color progressFillColor: Qt.darker(statusBgColor, 2.5)

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: statusText.contentWidth + 30
                    Layout.preferredHeight: 20
                    radius: 5
                    color: status.statusBgColor

                    Rectangle {
                        id: progressFill
                        anchors.left: status.left
                        anchors.top: status.top
                        anchors.bottom: status.bottom
                        implicitWidth: status.width * (status.progress / 100)
                        color: status.progressFillColor
                        radius: status.radius
                        opacity: 0.25
                        visible: !(status.progress === 100)

                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 4
                            Layout.preferredHeight: 4
                            radius: 4
                            color: status.statusTextColor
                        }

                        Text {
                            id: statusText
                            Layout.alignment: Qt.AlignVCenter
                            text: (status.progress > 0 && status.progress <= 100) ?
                                      `${root.modelData.status} ${status.progress} %` : root.modelData.status
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                            font.weight: 300
                            color: status.statusTextColor
                        }
                    }
                }

                ActionIconButton {
                    visible: !root.patNeeded || root.pat.length > 0
                    enabled: !root.isProcessing
                    iconText: Style.icons.arrowDown
                    tooltip: "Pull"
                    backgroundColor: Qt.darker(Style.colors.surfaceLight, 1.4)
                    textColor: Style.colors.foreground
                    onClicked: root.pullRequested(root.index, root.pat)
                }

                ActionIconButton {
                    visible: !root.patNeeded || root.pat.length > 0
                    enabled: !root.isProcessing
                    Layout.rightMargin: 10
                    iconText: Style.icons.download
                    tooltip: "Fetch"
                    backgroundColor: Qt.darker(Style.colors.surfaceLight, 1.4)
                    textColor: Style.colors.foreground
                    onClicked: root.fetchRequested(root.index, root.pat)
                }
            }

            // Path + Branch row
            RowLayout {
                id: mainRow
                Layout.fillWidth: true
                spacing: 15

                RowLayout {
                    Layout.preferredWidth: (mainRow.width - mainRow.spacing) / 2
                    spacing: 5

                    Text {
                        text: Style.icons.folder
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.foreground
                    }

                    ScrollingText {
                        Layout.fillWidth: true
                        text: root.modelData.path
                        font.pixelSize: 12
                        font.family: Style.fontTypes.roboto
                        color: Style.colors.mutedText
                        font.weight: 400
                        font.letterSpacing: 0
                    }
                }

                RowLayout {
                    Layout.preferredWidth: (mainRow.width - mainRow.spacing) / 2
                    spacing: 5

                    Text {
                        text: Style.icons.branch
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.foreground
                    }

                    ScrollingText {
                        Layout.fillWidth: true
                        text: root.modelData.branchName
                        font.pixelSize: 12
                        font.family: Style.fontTypes.roboto
                        color: Style.colors.mutedText
                        font.weight: 400
                        font.letterSpacing: 0
                    }
                }
            }

            // Remotes
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: Style.icons.cloud
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 12
                    color: Style.colors.foreground
                }

                ScrollingText {
                    Layout.fillWidth: true
                    text: root.modelData.remote
                    font.pixelSize: 12
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.mutedText
                    font.weight: 400
                    font.letterSpacing: 0
                }
            }

            // PAT
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                spacing: 15

                visible: root.patNeeded

                FormInputField {
                    id: textField
                    field.implicitHeight: 30
                    Layout.fillWidth: true
                    Layout.rightMargin: 10
                    placeholderText: "Personal Access Token"
                    icon: "\uF023"
                    echoMode: TextInput.Password
                }

                Button {
                    id: confirmButton
                    implicitWidth: 60
                    Layout.preferredHeight: 25
                    Layout.rightMargin: 10
                    hoverEnabled: true
                    visible: textField.field.text.length > 0

                    topInset: 0
                    bottomInset: 0
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0

                    contentItem: Text {
                        text: "Confirm"
                        font: confirmButton.font
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 3
                        color: confirmButton.down ? Style.colors.accentHover : confirmButton.hovered ? Style.colors.accentHover : Style.colors.accent
                    }

                    onClicked: {
                        root.pat = textField.text
                        confirmButton.visible = false
                        textField.enabled = false
                    }
                }
            }
        }
    }

    HoverHandler {
        id: msa
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: !root.isProcessing
        onTapped: root.clicked(root.index)
    }
}
