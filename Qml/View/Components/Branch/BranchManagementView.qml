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

    property string           currentBranch:    ""


    /* Object Properties
     * ****************************************************************************************/
    title: "Branch Management"
    icon: Style.icons.branch

    content: ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 12

        Connections {
            target: root
            onBranchControllerChanged: {
                content.update()
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true

            delegate: Rectangle {
                id: branchDelegate
                property var branch: modelData

                width: listView.width
                height: 38
                radius: 6
                color: Style.colors.secondaryBackground
                border.color: branch.name === root.currentBranch ? Style.colors.accent : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    // Active Indicator Dot
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: Style.colors.accent
                        visible: branch.name === root.currentBranch
                    }

                    Text {
                        text: branch.name
                        Layout.fillWidth: true
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 12
                        font.bold: branch.name === root.currentBranch
                        color: Style.colors.foreground
                        elide: Text.ElideMiddle
                    }

                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        RowLayout {
                            spacing: 4
                            visible: branch.name !== root.currentBranch

                            MouseArea {
                                id: checkoutArea
                                Layout.preferredWidth: checkoutRow.implicitWidth
                                Layout.preferredHeight: checkoutRow.implicitHeight
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (branch.name.startsWith("origin/")) {
                                        // Extract the local name (everything after 'origin/')
                                        let localName = branch.name.split('/').slice(1).join('/');

                                        // Create a local branch pointing to the remote's SHA
                                        let res = root.branchController.createBranch(branch.targetHash, localName);

                                        if (res.success) {
                                            // Checkout the newly created local branch
                                            root.branchController.checkoutBranch(localName);
                                        } else {
                                            console.error("Failed to track remote branch:", res.message);
                                        }
                                    } else {
                                        // Normal local checkout
                                        root.branchController.checkoutBranch(branch.name);
                                    }

                                    content.update();
                                }

                                RowLayout {
                                    id: checkoutRow
                                    anchors.fill: parent
                                    spacing: 4

                                    Text {
                                        text: Style.icons.check
                                        font.family: Style.fontTypes.font6Pro
                                        color: Style.colors.accent
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: "Checkout"
                                        font.family: Style.fontTypes.roboto
                                        color: Style.colors.accent
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }

                        // Delete Button
                        ActionIconButton {
                            iconText: Style.icons.trash
                            textColor: Style.colors.deletededFile
                            tooltip: "Delete Branch"
                            visible: branch.name !== root.currentBranch
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: {
                                let res = root.branchController.deleteBranch(branch.name)

                                if (res.success) {
                                    content.update();
                                }
                            }
                        }
                    }
                }
            }
        }


        Button {
            Layout.fillWidth: true
            implicitHeight: 44

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
                        font.pixelSize: 12
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add New Branch"
                        color: Style.colors.secondaryForeground
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            onClicked: {
                openAddEditPopup()
            }
        }

        function update() {
            if (branchController) {
                root.currentBranch = branchController.getCurrentBranchName()
                let res = branchController.getBranches();
                listView.model = res
            }
        }
    }
}
