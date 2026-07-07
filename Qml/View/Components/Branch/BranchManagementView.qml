import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * BranchManagementView
 * ************************************************************************************************/
UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController branchController: null

    property AddBranchPopup   addBranchPopup: null

    property string           currentBranch:    ""
    
    property NotificationController notificationController: null

    /* Object Properties
     * ****************************************************************************************/
    title: "Branch Management"
    icon: Style.icons.branch

    content: ColumnLayout {
        id: content

        property int currentIndex: 0
        property var localBranches: []
        property var remoteBranches: []

        onCurrentIndexChanged: content.updateModel()

        anchors.fill: parent
        spacing: 12

        Connections {
            target: root
            function onBranchControllerChanged() {
                content.update()
            }
        }

        Connections {
            target: root.branchController

            function onCurrentRepoChanged() {
                content.update()
            }
        }


        Connections {
            target: root.addBranchPopup

            function onAboutToHide() {
                content.update()
            }
        }

        ButtonGroup {
            id: headerButtonGroup
            exclusive: true
        }

        // View Control
        Rectangle {
            id: viewControl
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 10
            color: Style.colors.cardBackground

            RowLayout {
                anchors.fill: parent
                spacing: 4
                anchors.margins: 5

                Button {
                    id: localBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset:0
                    verticalPadding: 6

                    checkable: true
                    checked: content.currentIndex === 0
                    ButtonGroup.group: headerButtonGroup

                    onClicked: content.currentIndex = 0

                    contentItem: Item {
                        anchors.fill: parent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: Style.icons.laptop
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Local"
                                font.pixelSize: Style.appFont.h3Pt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    background: Rectangle {
                        radius: viewControl.radius
                        color: localBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }
                }

                Button {
                    id: remoteBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset:0
                    verticalPadding: 6

                    checkable: true
                    checked: content.currentIndex === 1
                    ButtonGroup.group: headerButtonGroup

                    onClicked: content.currentIndex = 1

                    contentItem: Item {
                        anchors.fill: parent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: Style.icons.cloud
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Remote"
                                font.pixelSize: Style.appFont.h3Pt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    background: Rectangle {
                        radius: viewControl.radius
                        color: remoteBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }
                }
            }
        }

        BranchesList {
            id: branchesList
            isLocal: content.currentIndex === 0
            currentBranch: root.currentBranch
            branchController: root.branchController
            notificationController: root.notificationController
            onUpdateRequested: content.update()
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 44
            visible: content.currentIndex === 0

            background: Rectangle {
                radius: 8
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            contentItem: Item {
                anchors.fill: parent

                Row {
                    spacing: 10
                    anchors.centerIn: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.plus
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.mediumPt
                        color: Style.colors.textButton
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add New Branch"
                        color: Style.colors.textButton
                        font.pixelSize: Style.appFont.h3Pt
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            onClicked: {
                openAddBranchPopup()
            }
        }

        function update() {
            if (branchController) {
                root.currentBranch = branchController.getCurrentBranchName()
                let res = branchController.getBranches();

                content.localBranches = res.filter(branch => branch["isLocal"])
                content.remoteBranches = res.filter(branch => branch["isRemote"])

                content.updateModel(res)
            }
        }

        function updateModel(res) {
            branchesList.model = content.currentIndex === 0 ? content.localBranches : content.remoteBranches
        }
    }

    /* Functions
     * ****************************************************************************************/

    function openAddBranchPopup() {
        addBranchPopup.branchController = root.branchController
        addBranchPopup.open()
    }
}
