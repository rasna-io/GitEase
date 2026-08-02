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
    property TagController          tagController:          null
    property var                    addTagPopup:            null
    property NotificationController notificationController: null
    property var                    tagListModel:           []
    property GuideController        guideController:        null

    title: "Tag Management"
    icon:  Style.icons.tag
    badgeCount: root.tagListModel.length

    TextEdit {
        id: clipboardHelper
        visible: false
    }

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

    function deleteTagLocal(tag) {
        let ctrl = root.tagController || uiSession.tagController;
        let res = ctrl.remove(tag.name);
        if (res.success) {
            if (root.notificationController)
                root.notificationController.success("Tag deleted locally", "Tag", 2000);
            root.update();
        }
    }

    function deleteTagRemote(tag) {
        let ctrl = root.tagController || uiSession.tagController;
        let notif = root.notificationController;

        if (notif) notif.info("Deleting tag from remote...", "Remote", 1500);

        ctrl.pushDeleteTag(tag.name);
    }

    function copyTagName(tag) {
        clipboardHelper.text = tag.name
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        if (root.notificationController)
            root.notificationController.success("Tag name copied to clipboard", "Tag", 2000)
    }

    function copyTagHash(tag) {
        clipboardHelper.text = tag.commitId
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        if (root.notificationController)
            root.notificationController.success("Commit hash copied to clipboard", "Tag", 2000)
    }

    function buildTagMenu(tag) {
        return [
            { text: "Copy Name", icon: Style.icons.copy, action: function() { root.copyTagName(tag) } },
            { text: "Copy Hash", icon: Style.icons.copy, action: function() { root.copyTagHash(tag) } },
            { separator: true },
            { text: "Delete Tag (Local Only)", icon: Style.icons.trash, action: function() { root.deleteTagLocal(tag) } },
            { text: "Delete Tag from Remote (Origin)", icon: Style.icons.trash, action: function() { root.deleteTagRemote(tag) } }
        ]
    }

    content: ColumnLayout {
        anchors.fill: parent
        spacing: 6

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "tag_management_tutorial"
            guideName: "Tag Management"
            guideIcon: Style.icons.tag
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return internalListView },
                        icon: Style.icons.tag,
                        title: "Your Tags",
                        description: "Every tag in the repository is listed here. The first trash icon deletes it locally; the second deletes it from the remote too."
                    },
                    {
                        targetProvider: function() { return addTagBtn },
                        icon: Style.icons.plus,
                        title: "Create a Tag",
                        description: "Mark the current commit with a version label like v1.0.0 — handy for marking releases.",
                        commands: [{ command: "git tag <name>" }]
                    }
                ]
            }
        }

        ContextMenu {
            id: itemContextMenu
            parent: Overlay.overlay
            width: 220
        }

        ListView {
            id: internalListView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 220)
            spacing: 6
            clip: true
            model: root.tagListModel

            delegate: Rectangle {
                id: tagDelegate
                width: internalListView.width
                height: Style.dp(35)
                radius: 4
                color: Style.colors.secondaryBackground

                MouseArea {
                    id: rightClickArea
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        var pos = mapToItem(Overlay.overlay, mouse.x, mouse.y)
                        itemContextMenu.menuModel = root.buildTagMenu(modelData)
                        itemContextMenu.x = pos.x
                        itemContextMenu.y = pos.y
                        itemContextMenu.open()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 6
                    spacing: 6

                    // 1. Tag Icon
                    Text {
                        text: Style.icons.tag || "#"
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.mediumPt
                        color: modelData.isAnnotated ? Style.colors.accent : Style.colors.secondaryText
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ScrollingText {
                        text: modelData.name
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.smallPt
                        font.bold: true
                        color: Style.colors.foreground

                        Layout.fillWidth: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        text: modelData.commitId.substring(0, 7)
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.mutedText

                        elide: Text.ElideRight
                    }

                    // 3. Delete Action (Fixed Position)
                    ActionIconButton {
                        iconText: Style.icons.trash
                        textColor: Style.colors.modifiediedFile
                        tooltip: "Delete Tag (Local Only)"
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        onClicked: root.deleteTagLocal(modelData)
                    }

                    ActionIconButton {
                        iconText: Style.icons.trash
                        textColor: Style.colors.deletededFile
                        tooltip: "Delete Tag from Remote (Origin)"
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        onClicked: root.deleteTagRemote(modelData)
                    }
                }
            }

            onContentHeightChanged: root.pageScrollBlocking = internalListView.contentHeight > internalListView.height + 1

            // Empty State
            Label {
                anchors.centerIn: parent
                text: "No tags available"
                color: Style.colors.secondaryText
                visible: internalListView.count === 0
                font.pixelSize: Style.appFont.smallPt
            }
        }

        // Add Tag Button
        IconButton {
            id: addTagBtn
            Layout.fillWidth: true
            implicitHeight: Style.dp(25)

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.plus
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.textButton
            text: "Add New Tag"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: addTagBtn.enabled ? Style.colors.accent : Style.colors.disabledButton
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

    Connections {
        target: root.tagController || uiSession.tagController

        function onPushTagFinished(result) {
            if (result.success) {
                if (root.notificationController)
                    root.notificationController.success("Tag created and pushed", "Success", 3000)
            } else {
                if (root.notificationController)
                    root.notificationController.warning("Tag created locally but failed to push", "Sync Warning", 5000);
            }

            root.update()
        }

        function onPushDeleteTagFinished(result, tagName) {
            if (result.success)
            {
                let ctrl = root.tagController || uiSession.tagController;
                if (root.notificationController) root.notificationController.success("Tag deleted from remote", "Success", 3000);
                ctrl.remove(tagName);
                root.update();
            }
            else
                if (root.notificationController) root.notificationController.error("Failed to delete from remote: " + result.errorMessage, "Error", 5000);
        }
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
