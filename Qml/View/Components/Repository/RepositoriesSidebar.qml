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
    property int                     detachLaunchDistance: 96
    property bool                    detachActive:         false
    property bool                    detachPreviewVisible: false
    property bool                    detachLaunching:      false
    property real                    detachX:              0
    property real                    detachY:              0
    property real                    detachOriginX:        0
    property real                    detachOriginY:        0
    property real                    detachOriginScreenX:  0
    property real                    detachOriginScreenY:  0
    property real                    detachWidth:          30
    property real                    detachHeight:         30
    property real                    detachHotspotX:       16
    property real                    detachHotspotY:       16
    property real                    detachProgress:       0
    property real                    detachLastDistance:   0
    property real                    detachPreviewSize:    30
    property real                    detachPreviewOpacity: 0
    property real                    detachLaunchTargetX:  0
    property real                    detachLaunchTargetY:  0
    property string                  detachRepositoryName: ""
    property string                  detachRepositoryPath: ""
    property string                  detachRepositoryInitials: "?"
    property color                   detachRepositoryColor: "#B9FAB9"

    /* Signals
     * ****************************************************************************************/
    signal newRepositoryRequested()

    /* JavaScript Functions
     * ****************************************************************************************/
    function repositoryInitials(repository) {
        const n = (repository && repository.name) ? repository.name : "";

        if (n.length >= 2)
            return (n.charAt(0) + n.charAt(1)).toUpperCase();

        if (n.length === 1)
            return n.charAt(0).toUpperCase();

        return "?";
    }

    function beginDetachPreview(repository, sourceItem, pointX, pointY) {
        if (!repository || root.detachLaunching)
            return;

        detachCancelAnimation.stop();
        detachLaunchAnimation.stop();

        const itemPosition = sourceItem.mapToItem(root, 0, 0);
        const screenPosition = sourceItem.mapToGlobal(0, 0);
        const pointerScreenPosition = sourceItem.mapToGlobal(pointX, pointY);
        const sourceAvatarCenterX = Math.min(sourceItem.width, sourceItem.height) / 2;
        const sourceAvatarCenterY = sourceItem.height / 2;
        const previewRadius = root.detachPreviewSize / 2;

        root.detachOriginX = itemPosition.x + sourceAvatarCenterX - previewRadius;
        root.detachOriginY = itemPosition.y + sourceAvatarCenterY - previewRadius;
        root.detachOriginScreenX = screenPosition.x + sourceAvatarCenterX - previewRadius;
        root.detachOriginScreenY = screenPosition.y + sourceAvatarCenterY - previewRadius;
        root.detachX = pointerScreenPosition.x - previewRadius;
        root.detachY = pointerScreenPosition.y - previewRadius;
        root.detachWidth = root.detachPreviewSize;
        root.detachHeight = root.detachPreviewSize;
        root.detachHotspotX = previewRadius;
        root.detachHotspotY = previewRadius;
        root.detachRepositoryName = repository.name ?? "";
        root.detachRepositoryPath = repository.path ?? "";
        root.detachRepositoryInitials = root.repositoryInitials(repository);
        root.detachRepositoryColor = repository.color ?? "#B9FAB9";
        root.detachProgress = 0;
        root.detachLastDistance = 0;
        root.detachPreviewOpacity = 0;
        root.detachPreviewVisible = false;
        root.detachActive = true;
    }

    function updateDetachPreview(pointerX, pointerY, distance) {
        if (!root.detachActive || root.detachLaunching)
            return;

        root.detachX = pointerX - root.detachHotspotX;
        root.detachY = pointerY - root.detachHotspotY;
        root.detachProgress = Math.min(1.0, Math.max(0.0, distance / root.detachLaunchDistance));
        root.detachLastDistance = distance;
        root.detachPreviewVisible = distance > 6;
        root.detachPreviewOpacity = root.detachPreviewVisible
                ? Math.min(0.96, 0.14 + root.detachProgress * 0.82)
                : 0;
    }

    function cancelDetachPreview() {
        if (!root.detachActive || root.detachLaunching)
            return;

        if (!root.detachPreviewVisible) {
            resetDetachPreview();
            return;
        }

        detachCancelAnimation.restart();
    }

    function commitDetachPreview() {
        if (!root.detachActive || root.detachLaunching || root.detachRepositoryPath.length === 0)
            return;

        root.detachLaunching = true;
        root.detachPreviewVisible = true;
        root.detachProgress = 1.0;
        root.detachPreviewOpacity = 1.0;

        const dx = root.detachX - root.detachOriginScreenX;
        const dy = root.detachY - root.detachOriginScreenY;
        const distance = Math.max(1.0, Math.sqrt(dx * dx + dy * dy));

        root.detachLaunchTargetX = root.detachX + (dx / distance) * 54;
        root.detachLaunchTargetY = root.detachY + (dy / distance) * 54 - 8;
        detachLaunchAnimation.restart();
    }

    function launchDetachedRepository() {
        const path = root.detachRepositoryPath;

        if (path.length === 0)
            return;

        TaskbarHelper.launchNewInstance(path);

        if (root.repositoryController)
            root.repositoryController.closeRepo(path);
    }

    function resetDetachPreview() {
        root.detachActive = false;
        root.detachPreviewVisible = false;
        root.detachLaunching = false;
        root.detachProgress = 0;
        root.detachLastDistance = 0;
        root.detachPreviewOpacity = 0;
        root.detachRepositoryName = "";
        root.detachRepositoryPath = "";
        root.detachRepositoryInitials = "?";
    }

    /* Children
     * ****************************************************************************************/
    Item {
        anchors.fill: parent

        // Repository list - anchored to bottom with flexible height
        Flickable {
            id: flickable
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: addButton.top

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
                        id: repositoryDelegate

                        width: parent.width
                        height: repositoryRow.implicitHeight + 8
                        z: repoMouseArea.pressed ? 2 : 0

                        property bool detachSource: root.detachRepositoryPath.length > 0
                                                    && modelData
                                                    && root.detachRepositoryPath === modelData.path

                        Row {
                            id: repositoryRow
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4
                            y: repoMouseArea.pressed ? -1 : 0
                            opacity: repositoryDelegate.detachSource && root.detachPreviewVisible
                                     ? 1.0 - (root.detachProgress * 0.38)
                                     : 1.0

                            Behavior on y {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }

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
                                scale: repoMouseArea.pressed
                                       ? 0.96
                                       : (repoMouseArea.containsMouse ? 1.035 : 1.0)

                                property color repoColor: modelData?.color ?? "#B9FAB9"
                                color: repoMouseArea.containsMouse ?  Qt.darker(repoColor, 1.25) : repoColor
                                border.width: repoMouseArea.pressed || repoMouseArea.containsMouse ? 1 : 0
                                border.color: repoMouseArea.pressed
                                              ? Style.colors.accent
                                              : Qt.rgba(1, 1, 1, 0.26)

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                Text {
                                    property string initials: root.repositoryInitials(modelData)

                                    text: root.expanded ? modelData.name : initials
                                    font.family: Style.fontTypes.roboto
                                    font.weight: 400
                                    font.pixelSize:root.expanded ? 16 : 24
                                    Behavior on font.pixelSize {
                                        NumberAnimation {
                                            duration: 120
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    color: Style.theme == Style.Light ?
                                               Qt.darker(repositoryAvatar.repoColor, 2.0) :
                                               Qt.lighter(repositoryAvatar.repoColor, 2.0)
                                    elide: Text.ElideRight

                                    x: root.expanded ? 5 : ((repositoryAvatar.width - width) / 2)
                                    y: (repositoryAvatar.height - height) / 2

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 120
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    id: repoMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    property real pressX: 0
                                    property real pressY: 0
                                    property bool launchTriggered: false
                                    property bool dragStarted: false
                                    property bool suppressClick: false

                                    onPressed: {
                                        pressX = mouseX
                                        pressY = mouseY
                                        launchTriggered = false
                                        dragStarted = false
                                        suppressClick = false
                                        root.beginDetachPreview(modelData, repositoryAvatar, mouseX, mouseY)
                                    }

                                    onPositionChanged: {
                                        if (pressed) {
                                            repoMouseArea.cursorShape = Qt.SizeAllCursor

                                            let dx = mouseX - pressX
                                            let dy = mouseY - pressY
                                            let distance = Math.sqrt(dx*dx + dy*dy)
                                            let pointerPosition = repoMouseArea.mapToGlobal(mouseX, mouseY)

                                            dragStarted = distance > 6
                                            root.updateDetachPreview(pointerPosition.x, pointerPosition.y, distance)
                                        }
                                    }

                                    onReleased: {
                                        let dx = mouseX - pressX
                                        let dy = mouseY - pressY
                                        let distance = Math.sqrt(dx*dx + dy*dy)
                                        let pointerPosition = repoMouseArea.mapToGlobal(mouseX, mouseY)

                                        dragStarted = distance > 6
                                        suppressClick = dragStarted
                                        repoMouseArea.cursorShape = Qt.PointingHandCursor
                                        root.updateDetachPreview(pointerPosition.x, pointerPosition.y, distance)

                                        if (distance >= root.detachLaunchDistance && root.repositories.length > 1) {
                                            launchTriggered = true
                                            suppressClick = true
                                            root.commitDetachPreview()
                                        } else {
                                            root.cancelDetachPreview()
                                        }
                                    }

                                    onCanceled: {
                                        suppressClick = launchTriggered || dragStarted
                                        repoMouseArea.cursorShape = Qt.PointingHandCursor

                                        if (!launchTriggered)
                                            root.cancelDetachPreview()
                                    }

                                    onClicked: {
                                        if (suppressClick) {
                                            suppressClick = false
                                        } else if (root.repositoryController) {
                                            root.repositoryController.selectRepository(modelData.id)
                                        }
                                    }
                                }
                            }

                            ToolTip {
                                id: tip
                                parent: repositoryRow
                                visible: repoMouseArea.containsMouse && !repoMouseArea.pressed && !root.detachActive
                                delay: 200
                                timeout: 5000
                                text: modelData.path

                                x: (repositoryRow.width - width) / 2
                                y: -height + 10

                                padding: 6

                                contentItem: Text {
                                    text: tip.text
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 11
                                    color: "#ffffff"
                                }

                                background: Rectangle {
                                    radius: 6
                                    color: Qt.rgba(0, 0, 0, 0.85)
                                    border.color: Qt.rgba(1, 1, 1, 0.12)
                                    border.width: 1
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
            height: 33
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            radius: 6
            color: addRepoMouse.containsMouse ^ Style.theme == Style.Light ?
                       Qt.lighter(Style.colors.navButton, 2.0) :
                       Qt.darker(Style.colors.navButton, 2.0)

            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 8

                Item {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Layout.preferredWidth: 20
                    Layout.minimumWidth: 20
                    Layout.maximumWidth: 20
                    Layout.preferredHeight: 20

                    Text {
                        anchors.centerIn: parent
                        text: Style.icons.plus
                        font.family: Style.fontTypes.font6Pro
                        font.weight: 400
                        font.pixelSize: 14
                        color: addRepoMouse.containsMouse ^ Style.theme == Style.Light ?
                                   Qt.darker(Style.colors.navButton, 2.0) :
                                   Qt.lighter(Style.colors.navButton, 2.0)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Text {
                    visible: root.expanded
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Add new"
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    color: addRepoMouse.containsMouse ^ Style.theme == Style.Light ?
                               Qt.darker(Style.colors.navButton, 2.0) :
                               Qt.lighter(Style.colors.navButton, 2.0)
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.expanded
                }
            }

            // Make the whole row clickable
            MouseArea {
                id: addRepoMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: root.newRepositoryRequested()
            }
        }
    }

    Window {
        id: detachPreviewWindow
        width: root.detachPreviewSize + 88
        height: root.detachPreviewSize + 18
        x: Math.round(root.detachX - 9)
        y: Math.round(root.detachY - 9)
        flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint | Qt.WindowTransparentForInput
        color: "transparent"
        visible: root.detachPreviewVisible || detachCancelAnimation.running || detachLaunchAnimation.running
        opacity: root.detachPreviewOpacity

        Rectangle {
            id: detachWindowCard
            width: root.detachPreviewSize
            height: root.detachPreviewSize
            x: 9
            y: 9
            radius: 6
            clip: true
            color: root.detachRepositoryColor
            scale: root.detachLaunching ? 1.12 : 1.0 + root.detachProgress * 0.12
            border.width: 1
            border.color: Style.theme == Style.Light
                          ? Qt.darker(root.detachRepositoryColor, 1.35)
                          : Qt.lighter(root.detachRepositoryColor, 1.35)

            Text {
                anchors.centerIn: parent
                text: root.detachRepositoryInitials
                font.family: Style.fontTypes.roboto
                font.weight: 600
                font.pixelSize: 20
                color: Style.theme == Style.Light
                       ? Qt.darker(root.detachRepositoryColor, 2.15)
                       : Qt.lighter(root.detachRepositoryColor, 2.0)
            }
        }
    }

    SequentialAnimation {
        id: detachCancelAnimation

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "detachX"
                to: root.detachOriginScreenX
                duration: 140
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "detachY"
                to: root.detachOriginScreenY
                duration: 140
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "detachProgress"
                to: 0
                duration: 140
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "detachPreviewOpacity"
                to: 0
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: root.resetDetachPreview()
        }
    }

    SequentialAnimation {
        id: detachLaunchAnimation

        PauseAnimation {
            duration: 70
        }

        ScriptAction {
            script: root.launchDetachedRepository()
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "detachX"
                to: root.detachLaunchTargetX
                duration: 220
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "detachY"
                to: root.detachLaunchTargetY
                duration: 220
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "detachPreviewOpacity"
                to: 0
                duration: 220
                easing.type: Easing.InCubic
            }
        }

        ScriptAction {
            script: root.resetDetachPreview()
        }
    }
}
