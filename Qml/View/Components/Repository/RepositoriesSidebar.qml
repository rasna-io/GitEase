import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RepositoriesSidebar
 * Sidebar component with + button and repository squares showing first letter
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController    repositoryController: null
    property var                     repositories:         []
    property Repository              currentRepository:    null
    property var                     recentRepositories:   []

    property bool                    expanded:             false

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/

    Popup {
        id: repositorySelectorPopup

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        parent: root.Window.window.contentItem

        width: 523
        height: 475

        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 2) : 0

        padding: 0

        property bool busy: false
        property real progress: 0

        background: Rectangle {
            color: "transparent"
        }

        // Dim overlay
        Overlay.modal: Rectangle {
            color: "#000000"
            opacity: 0.35
        }

        contentItem: Rectangle {
            color: Style.colors.primaryBackground
            radius: 16
            clip: true
            border.color: Style.colors.accent
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 0

                PageHeader {
                    pageTitle: "Open a Repository"
                    showBackButton: false
                }

                RepositorySelector {
                    id: repositorySelector
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    showDescription: true
                    descriptionText: "Choose how you want to get started with your Git repository"
                    recentRepositories: root.recentRepositories
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    Layout.preferredWidth: 320
                    Layout.preferredHeight: 43

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            id: cancelButton
                            Layout.fillWidth: true
                            flat: false
                            Material.background: Style.colors.accent
                            Material.foreground: "white"
                            text: Style.icons.arrowLeft + " Cancel"
                            background: Rectangle {
                                radius: 3
                                color: cancelButton.hovered ? Style.colors.accentHover : Style.colors.accent
                            }
                            onClicked: repositorySelectorPopup.close()
                        }

                        Button {
                            id: submitButton
                            Layout.fillWidth: true
                            flat: false
                            Material.background: Style.colors.accent
                            Material.foreground: "white"

                            text: {
                                if (repositorySelectorPopup.busy) {
                                    return Math.round(repositorySelectorPopup.progress) + " %"
                                }
                                return "Open " + Style.icons.arrowRight
                            }

                            enabled: {
                                if (repositorySelectorPopup.busy)
                                    return false

                                switch(repositorySelector.currentTabIndex) {
                                    case Enums.RepositorySelectorTab.Recents:
                                    case Enums.RepositorySelectorTab.Open:
                                        return repositorySelector.selectedPath !== ""

                                    case Enums.RepositorySelectorTab.Clone:
                                        return repositorySelector.selectedPath !== "" && repositorySelector.selectedUrl !== ""

                                    default:
                                        return false
                                }
                            }

                            background: Rectangle {
                                radius: 3
                                color: submitButton.enabled ?
                                           (submitButton.hovered ? Style.colors.accentHover : Style.colors.accent) :
                                           Style.colors.disabledButton

                                // Gray background bar
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#CCCCCC"
                                    radius: 3
                                    visible: repositorySelectorPopup.busy

                                    // Blue progress bar
                                    Rectangle {
                                        width: repositorySelectorPopup.busy ? parent.width * repositorySelectorPopup.progress / 100 : 0
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        color: Style.colors.accent
                                        radius: 3
                                        Behavior on width { NumberAnimation { duration: 100 } }
                                    }
                                }
                            }

                            onClicked: {
                                repositorySelectorPopup.submitFromPopup()
                            }
                        }
                    }
                }

                Connections {
                    target: GitService

                    function onCloneFinished() {
                        repositorySelectorPopup.busy = false
                        repositorySelectorPopup.progress = 0
                        repositorySelectorPopup.close()
                    }

                    function onCloneProgress(progress) {
                        repositorySelectorPopup.progress = progress
                    }
                }
            }
        }

        onClosed: {
            // reset state
            busy = false
            progress = 0
            repositorySelector.errorMessage = ""
            repositorySelector.selectedPath = ""
        }

        function submitFromPopup() {
            if (!root.repositoryController)
                return

            switch(repositorySelector.currentTabIndex) {
                case Enums.RepositorySelectorTab.Recents:
                case Enums.RepositorySelectorTab.Open: {
                    let ok = root.repositoryController.openRepository(repositorySelector.selectedPath)
                    if (ok)
                        repositorySelectorPopup.close()
                    return
                }

                case Enums.RepositorySelectorTab.Clone: {
                    let res = root.repositoryController.cloneRepository(repositorySelector.selectedPath, repositorySelector.selectedUrl)

                    // RepositoryController returns the raw GitService result object
                    if (res && res.success) {
                        repositorySelectorPopup.busy = true
                        repositorySelectorPopup.progress = 0
                    } else {
                        repositorySelector.errorMessage = (res && res.error) ? res.error : "Clone failed"
                    }
                    return
                }

                default:
                    return
            }
        }
    }

    Item {
        anchors.fill: parent

        // Repository list - anchored to bottom with flexible height
        Flickable {
            id: flickable
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: addButton.top
            anchors.bottomMargin: 12

            height: Math.min(repositoryColumn.height, parent.height - addButton.height - 12)
            contentHeight: repositoryColumn.height
            clip: true

            Column {
                id: repositoryColumn
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.repositories

                    Item {
                        width: parent.width
                        height: repositoryRow.implicitHeight + 8

                        Row {
                            id: repositoryRow
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                color: (modelData.id === (currentRepository?.id ?? -1)) ? "#074E96" : "transparent"
                                width: 3
                                height: 28
                                radius: 2
                            }

                            Rectangle {
                                id: repositoryAvatar
                                anchors.verticalCenter: parent.verticalCenter
                                height: 33
                                radius: 6
                                clip: true

                                width: root.expanded ? repositoryRow.width - (repositoryRow.spacing + 2 + repositoryRow.anchors.margins) : 33
                                color: repoMouseArea.containsMouse ?  Qt.darker("#B9FAB9", 1.25) : "#B9FAB9"

                                Text {
                                    property string initials: {
                                        const n = (modelData && modelData.name) ? modelData.name : "";
                                        if (n.length >= 2) return (n.charAt(0) + n.charAt(1)).toUpperCase();
                                        if (n.length === 1) return n.charAt(0).toUpperCase();
                                        return "?";
                                    }

                                    text: root.expanded ? modelData.name : initials
                                    font.family: Style.fontTypes.roboto
                                    font.weight: 400
                                    font.pixelSize:root.expanded ? 16 : 24
                                    Behavior on font.pixelSize {
                                        NumberAnimation {
                                            duration: 10;
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    color: Qt.darker(parent.color, 2.0)
                                    elide: Text.ElideRight

                                    x: root.expanded ? 5 : ((repositoryAvatar.width - width) / 2)
                                    y: (repositoryAvatar.height - height) / 2

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 10;
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    id: repoMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: root.repositoryController.openRepository(modelData.path)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Add button - anchored at bottom
        Rectangle {
            id: addButton
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            width: 33
            height: 33
            radius: 6
            color: "#F3F3F3"

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 22
                font.family: Style.fontTypes.roboto
                font.weight: 400
                color: "#C9C9C9"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: repositorySelectorPopup.open()
                onEntered: parent.color = Qt.darker("#F3F3F3", 2)
                onExited: parent.color = "#F3F3F3"
            }
        }
    }
}
