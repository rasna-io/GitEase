import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * TagManagementView
 * ************************************************************************************************/
UtilitiesCard {
    id: root

    /* Property Declarations */
    property TagController tagController: null
    property var           addTagPopup:   null
    property NotificationController notificationController: null
    property var           tagListModel:  []

    title: "Tag Management"
    icon:  Style.icons.tag

    /* Logic */
    function update() {
        let ctrl = root.tagController || (typeof uiSession !== "undefined" ? uiSession.tagController : null);

        if (ctrl) {
            let res = ctrl.list();
            if (res && res.success) {
                root.tagListModel = res.data;
                console.log("GitEase: Tag list updated.");
            }
        }
    }

    content: ColumnLayout {
        anchors.fill: parent
        spacing: 12

        ListView {
            id: internalListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true
            model: root.tagListModel

            delegate: Rectangle {
                id: tagDelegate
                width: internalListView.width
                height: 48
                radius: 6
                color: Style.colors.secondaryBackground

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 10

                    // 1. Tag Icon
                    Text {
                        text: Style.icons.tag || "#"
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 14
                        color: modelData.isAnnotated ? Style.colors.accent : Style.colors.secondaryForeground
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // 2. Text Column (Flexible Space)
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: modelData.name
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                            font.bold: true
                            color: Style.colors.foreground

                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.commitId.substring(0, 7)
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 10
                            color: Style.colors.secondaryForeground

                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    // 3. Delete Action (Fixed Position)
                    ActionIconButton {
                        iconText: Style.icons.trash
                        textColor: Style.colors.modifiediedFile
                        tooltip: "Delete Tag (Local Only)"
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        onClicked: {
                            let ctrl = root.tagController || uiSession.tagController;
                            let res = ctrl.remove(modelData.name);
                            if (res.success) {
                                if (root.notificationController)
                                    root.notificationController.success("Tag deleted locally", "Tag", 2000);
                                root.update();
                            }
                        }
                    }

                    ActionIconButton {
                        iconText: Style.icons.trash
                        textColor: Style.colors.deletededFile
                        tooltip: "Delete Tag from Remote (Origin)"
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        onClicked: {
                            let ctrl = root.tagController || uiSession.tagController;
                            let notif = root.notificationController;

                            if (notif) notif.info("Deleting tag from remote...", "Remote", 1500);

                            let res = ctrl.pushDeleteTag(modelData.name);

                            if (res.success) {
                                if (notif) notif.success("Tag deleted from remote", "Success", 3000);
                                ctrl.remove(modelData.name);
                                root.update();
                            } else {
                                if (notif) notif.error("Failed to delete from remote: " + res.errorMessage, "Error", 5000);
                            }
                        }
                    }
                }
            }

            // Empty State
            Label {
                anchors.centerIn: parent
                text: "No tags available"
                color: Style.colors.secondaryForeground
                visible: internalListView.count === 0
                font.pixelSize: 12
            }
        }

        // Add Tag Button
        Button {
            id: addTagBtn
            Layout.fillWidth: true
            implicitHeight: 44

            background: Rectangle {
                radius: 8
                color: addTagBtn.enabled ? Style.colors.accent : Style.colors.disabledButton
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
                        color: Style.colors.textButton
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add New Tag"
                        color: Style.colors.textButton
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
            onClicked: {
                if (root.addTagPopup) {
                    root.addTagPopup.tagController = root.tagController || uiSession.tagController;
                    root.addTagPopup.open();
                }
            }
        }
    }

    /* Event Handling */
    Connections {
        target: (typeof uiSession !== "undefined") ? uiSession : null
        function onTagControllerChanged() { root.update() }
    }

    Timer {
        id: initTimer
        interval: 500
        running: true
        repeat: false
        onTriggered: root.update()
    }

    Component.onCompleted: root.update()
}
