import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RepositorySelector
 * Reusable repository selector with tabs (Recents, Open, Clone)
 * Can be used in welcome flow or elsewhere
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController repositoryController

    property var recentRepositories

    property alias currentTabIndex: tabbedView.currentIndex

    property bool showDescription: true

    property string descriptionText: "Choose how you want to get started with your Git repository"

    property string selectedPath: ""

    property string selectedUrl: repositoryUrlField.field.text

    property string errorMessage: ""

    property bool busy: false

    property real progress: 0



    /* Signals
     * ****************************************************************************************/
    signal cloneFinished()

    /* Children
     * ****************************************************************************************/

    onCurrentTabIndexChanged: {
        reset()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Description text
        Text {
            visible: root.showDescription
            Layout.fillWidth: true
            Layout.bottomMargin: 24
            Layout.alignment: Qt.AlignHCenter
            text: root.descriptionText
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            color: Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.fontTypes.roboto
            font.weight: 300
            font.italic: true
            font.letterSpacing: 0
            Layout.maximumWidth: 450
        }

        // TabBar and StackLayout
        TabbedView {
            id: tabbedView
            Layout.fillWidth: true
            Layout.maximumWidth: 465
            Layout.alignment: Qt.AlignHCenter

            tabs: [
                { title: "Recents", icon: Style.icons.clock},
                { title: "Open", icon: Style.icons.folder },
                { title: "Clone", icon: Style.icons.download}
            ]

            stackLayout.Layout.preferredHeight: 200

            // Recents tab content
            Item {
                RecentRepositoriesList {
                    id: recentRepositoriesList
                    anchors.fill: parent
                    model: recentRepositories
                    onRepositoryClicked: function(name, path) {
                        root.selectedPath = path
                    }
                }
            }

            // Open tab content
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Description
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 30
                        Layout.bottomMargin: 10
                        text: "Browse and open a Git repository that already exists on your computer"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 13
                        font.family: Style.fontTypes.roboto
                        font.weight: 300
                        font.letterSpacing: 0
                        font.italic: true
                        color: Style.colors.mutedText
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Repository Location Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        FormInputField {
                            id: repositoryLocationField
                            label: "Repository Location"
                            placeholderText: "C:/Users/Username/Documents/MyRepository"
                            button: "Browse"
                            helperText: "Select a folder containing a Git repository"
                            field.text : selectedPath

                            onTextChanged: {
                                selectedPath = repositoryLocationField.text
                            }

                            onButtonClicked: {
                                folderDialog.open()
                            }
                        }
                    }
                }

                // Folder Dialog for selecting repository folder
                FolderDialog {
                    id: folderDialog
                    title: "Select Repository Folder"

                    onAccepted: {
                        var selectedFolder = folderDialog.selectedFolder
                        if (selectedFolder) {
                            var folderPath = selectedFolder.toString()
                            // Convert QUrl to local file path
                            // Remove file:/// prefix (Windows: file:///C:/path, Unix: file:///path)
                            if (folderPath.startsWith("file:///")) {
                                folderPath = folderPath.substring(8)
                            } else if (folderPath.startsWith("file://")) {
                                folderPath = folderPath.substring(7)
                            }

                            // Extract folder name for display
                            var pathParts = folderPath.split(/[\\/]/).filter(function(part) {
                                return part.length > 0
                            })
                            var folderName = pathParts.length > 0 ? pathParts[pathParts.length - 1] : folderPath

                            repositoryLocationField.field.text = folderPath
                            cloneLocationField.field.text = folderPath
                        }
                    }
                }
            }

            // Clone tab content
            Item {
                id: cloneTab

                property bool hasError: (root.errorMessage !== "" && root.currentTabIndex === Enums.RepositorySelectorTab.Clone)

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Description
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                        text: cloneTab.hasError ? root.errorMessage : "Initialize a new Git repository on your local machine"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 13
                        font.family: Style.fontTypes.roboto
                        font.weight: 300
                        font.letterSpacing: 0
                        font.italic: true
                        color: cloneTab.hasError ? Style.colors.error  : Style.colors.mutedText
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Input sections wrapper
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        // Repository URL Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            FormInputField {
                                id: repositoryUrlField
                                label: "Repository URL"
                                placeholderText: "https://github.com/username/repository.git"

                                onTextChanged: {
                                    selectedUrl = repositoryUrlField.text
                                }
                            }
                        }

                        // Clone to Location Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            FormInputField {
                                id: cloneLocationField
                                label: "Clone to Location"
                                placeholderText: "C:/Users/Username/Documents/Projects"
                                button: "Browse"

                                onTextChanged: {
                                    selectedPath = cloneLocationField.text
                                }

                                onButtonClicked: {
                                    folderDialog.open()
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    Connections {
        target: GitService

        function onCloneFinished() {
            root.busy = false
            root.progress = 0
            root.cloneFinished()
        }

        function onCloneProgress (progress){
            root.progress = progress
        }
    }


    function submit() {
        switch(root.currentTabIndex) {
            case Enums.RepositorySelectorTab.Recents:
            case Enums.RepositorySelectorTab.Open:
                return root.repositoryController.openRepository(root.selectedPath)

            case Enums.RepositorySelectorTab.Clone: {
                let res = root.repositoryController.cloneRepository(root.selectedPath, root.selectedUrl)
                root.busy = res.success

                if (!res.success) {
                    root.errorMessage = res.error
                }

                return false;
            }

            default:
                return false;
        }
    }

    function reset() {
        root.busy = false
        root.progress = 0
        repositoryLocationField.field.text = ""
        cloneLocationField.field.text = ""
        repositoryUrlField.field.text = ""
        root.selectedPath = ""
        recentRepositoriesList.selectedIndex = -1
        root.errorMessage = ""
    }
}

