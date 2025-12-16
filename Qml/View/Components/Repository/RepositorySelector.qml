import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
    property bool showDescription: true
    property string descriptionText: "Choose how you want to get started with your Git repository"

    /* Signals
     * ****************************************************************************************/
    signal repositorySelected(string name, string path)

    /* Children
     * ****************************************************************************************/
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
                    anchors.fill: parent
                    model: ListModel {
                        ListElement { name: "My Project"; path: "C:/Users/Username/Documents/MyProject" }
                        ListElement { name: "GitEase"; path: "F:/Projects/Ronia/GitEase" }
                        ListElement { name: "WebApp Dashboard"; path: "D:/Development/WebApp/Dashboard" }
                        ListElement { name: "Mobile App"; path: "C:/Projects/MobileApp" }
                        ListElement { name: "Backend API"; path: "D:/Work/Backend/API" }
                        ListElement { name: "Frontend React"; path: "C:/Dev/Frontend/React" }
                        ListElement { name: "Data Analysis"; path: "F:/Research/DataAnalysis" }
                        ListElement { name: "Machine Learning"; path: "D:/AI/MachineLearning" }
                    }
                    onRepositoryClicked: function(name, path) {
                        root.repositorySelected(name, path)
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
                            helperText: "Use the same email as your GitHub/GitLab account to link commits"
                        }
                    }
                }
            }

            // Clone tab content
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Description
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                        text: "Initialize a new Git repository on your local machine"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 13
                        font.family: Style.fontTypes.roboto
                        font.weight: 300
                        font.letterSpacing: 0
                        font.italic: true
                        color: Style.colors.mutedText
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
                                button: "Browse"
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
                            }
                        }
                    }
                }
            }
        }
    }
}

