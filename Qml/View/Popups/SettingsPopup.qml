import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SettingsPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel              appModel

    property AppSettings           appSettings: appModel?.appSettings ?? null

    property FileIO                fileIO

    property int                   currentPage: 0


    /* Object Properties
     * ****************************************************************************************/
    width: parent.width * 0.8
    height: parent.height * 0.8

    onClosed: load()
    onOpened: load()

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 15


            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                PagesRail {
                    Layout.preferredWidth: parent.width * 0.15
                    Layout.fillHeight: true
                    currentId: root.currentPage
                    radius: 5
                    color: Style.colors.secondaryBackground
                    model: [
                        {id: 0, title: "General", icon: Style.icons.slider},
                        {id: 1, title: "SSH", icon: Style.icons.terminal},
                        {id: 2, title: "Appearence", icon: Style.icons.palette},
                    ]
                    expanded: true
                    onClicked: (modelData) => {
                        root.currentPage = modelData.id
                    }
                }

                Rectangle {
                    id: settingsContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Style.colors.secondaryBackground
                    radius: 5
                    clip: true

                    SwipeView {
                        anchors.fill: parent
                        currentIndex: root.currentPage
                        interactive: false

                        Item {
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 10
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20

                                spacing: 20

                                CheckboxItem {
                                    id: displayAvatar
                                    Layout.fillWidth: true
                                    title: "Display Avatar"
                                    description: "Show profile Avatar on graph view"
                                    checked: root.appSettings?.generalSettings?.showAvatar ?? false
                                }

                                PathSelectorItem {
                                    id: defaultPath
                                    Layout.fillWidth: true
                                    fileIO: root.fileIO
                                    title: "Default Path"
                                    description: "Select Default path to open or clone location"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                            }
                        }
                        Item {
                        }

                        Item {
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 10
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20

                                spacing: 20

                                ComboboxItem {
                                    id: theme
                                    Layout.fillWidth: true
                                    title: "Theme"
                                    description: "Select theme"
                                    cmb.model: ["Modern Light", "Modern Dark"]
                                }




                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                            }

                        }

                    }
                }
            }

            Row {
                spacing: 8
                Layout.alignment: Qt.AlignRight

                Button {
                    flat: true
                    text: "Cancel"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    onClicked: root.close()
                }

                Button {
                    flat: true
                    text: "Save"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    onClicked: {
                        root.apply()
                        root.close()
                    }
                }

                Button {
                    flat: true
                    text: "Apply"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    onClicked: root.apply()
                }
            }
        }
    }

    function apply() {
        root.appSettings.generalSettings.showAvatar = displayAvatar.checked
        root.appSettings.generalSettings.defaultPath = defaultPath.text
        root.appSettings.appearanceSettings.currentTheme = theme.cmb.displayText

        root.appModel.save()
    }

    function load() {
        displayAvatar.checked = root.appSettings?.generalSettings?.showAvatar
        defaultPath.text = root.appSettings.generalSettings.defaultPath

        theme.cmb.currentIndex = theme.cmb.model.indexOf(root.appSettings.appearanceSettings.currentTheme)
    }

}
