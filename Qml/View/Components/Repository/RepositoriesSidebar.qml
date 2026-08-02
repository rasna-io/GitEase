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
    property GuideController         guideController:      null
    property var                     repositories:         []
    property Repository              currentRepository:    null
    property var                     recentRepositories:   []

    property var                     branchByPath:         ({})
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

    /* Reusable status badge (icon + count pill)
     * ****************************************************************************************/
    component StateBadge: Rectangle {
        id: badge

        property string icon: ""
        property int    count: 0
        property color  badgeColor: Style.colors.accent

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: badgeRow.implicitWidth + 8
        implicitHeight: 15
        radius: 4
        color: Qt.rgba(badge.badgeColor.r, badge.badgeColor.g, badge.badgeColor.b, 0.16)

        Row {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: badge.icon
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: 8
                color: badge.badgeColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: badge.count
                font.family: Style.fontTypes.inter
                font.weight: 700
                font.pixelSize: 9
                color: badge.badgeColor
            }
        }
    }

    /* Branch scanning
     * ****************************************************************************************/
    // Scratch controller used to read each repository's current branch without disturbing the
    // active session.
    BranchController {
        id: branchScanner
    }

    onRepositoriesChanged: Qt.callLater(root.refreshBranches)
    onCurrentRepositoryChanged: Qt.callLater(root.refreshBranches)
    Component.onCompleted: root.refreshBranches()

    /* Guide
     * ****************************************************************************************/
    GuideHoverTrigger {
        guideController: root.guideController
        guideId: "repositories_sidebar_tutorial"
        guideName: "Repositories Sidebar"
        guideIcon: Style.icons.folder
        stepsFactory: function() {
            return [
                {
                    targetProvider: function() { return flickable },
                    icon: Style.icons.folder,
                    title: "Open Repositories",
                    description: "Each card is an open repository. Click one to switch to it, or drag it outward and release to launch it in its own window."
                },
                {
                    targetProvider: function() { return addButton },
                    icon: Style.icons.plus,
                    title: "Add a Repository",
                    description: "Click here to open an existing repository or clone a new one."
                }
            ]
        }
    }

    /* Functions
     * ****************************************************************************************/
    function repositoryInitial(repository) {
        const n = (repository && repository.name) ? repository.name : "";
        return n.length >= 1 ? n.charAt(0).toUpperCase() : "?";
    }

    function repositoryColor(repository) {
        const ctrl = root.repositoryController;
        if (!ctrl)
            return (repository && repository.color) ? repository.color : "#B9FAB9";
        return ctrl.isValidRepoColor(repository ? repository.color : "")
                ? repository.color
                : ctrl.repoColor(repository ? repository.path : "");
    }

    //! Read every open repository's current branch through the scratch controller and cache it.
    function refreshBranches() {
        var map = {};
        var list = root.repositories || [];

        for (var i = 0; i < list.length; ++i) {
            var repo = list[i];
            if (repo && repo.cppObjectPtr) {
                branchScanner.currentRepo = repo.cppObjectPtr;
                var name = branchScanner.getCurrentBranchName();
                map[repo.path] = (name && name.length > 0) ? name : "";
            }
        }

        branchScanner.currentRepo = null;
        root.branchByPath = map;
    }

    function branchNameFor(repository) {
        if (!repository)
            return "—";
        var name = root.branchByPath[repository.path];
        return (name && name.length > 0) ? name : "—";
    }

    function repoStateFor(repository) {
        // todo
        // Replace with real per-repo status once a status
        //! backend that covers all open repositories is available.
        return ({ ahead: 0, behind: 0, dirty: false });
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
        root.detachRepositoryInitials = root.repositoryInitial(repository);
        root.detachRepositoryColor = root.repositoryColor(repository);
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
            anchors.bottomMargin: 8

            height: Math.min(repositoryColumn.height, parent.height - addButton.height - 12)
            contentHeight: repositoryColumn.height
            clip: true

            Column {
                id: repositoryColumn
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.repositories

                    Item {
                        id: repositoryDelegate

                        width: parent.width
                        height: card.height
                        z: repoMouseArea.pressed ? 2 : 0

                        readonly property bool   isCurrent: modelData
                                                          && modelData.id === (root.currentRepository?.id ?? -1)
                        readonly property color  repoColor: root.repositoryColor(modelData)
                        readonly property string branchName: root.branchNameFor(modelData)
                        readonly property var    repoState: root.repoStateFor(modelData)

                        property bool detachSource: root.detachRepositoryPath.length > 0
                                                    && modelData
                                                    && root.detachRepositoryPath === modelData.path

                        AccentCard {
                            id: card
                            width: parent.width
                            height: 44
                            peek: 4
                            accentRadius: 8
                            cardRadius: 7
                            cardClip: false
                            accentColor: repositoryDelegate.isCurrent ? repositoryDelegate.repoColor : "transparent"
                            cardColor: {
                                var fg = Style.colors.foreground
                                if (repositoryDelegate.isCurrent) {
                                    var base = Style.colors.secondaryBackground
                                    if (repoMouseArea.pressed)
                                        return Style.theme === Style.Light ? Qt.darker(base, 1.10) : Qt.lighter(base, 1.45)
                                    if (cardHover.hovered)
                                        return Style.theme === Style.Light ? Qt.darker(base, 1.05) : Qt.lighter(base, 1.28)
                                    return base
                                }
                                if (repoMouseArea.pressed)
                                    return Qt.rgba(fg.r, fg.g, fg.b, 0.09)
                                if (cardHover.hovered)
                                    return Qt.rgba(fg.r, fg.g, fg.b, 0.05)
                                return "transparent"
                            }
                            tintColor: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.08)
                            tintVisible: repositoryDelegate.isCurrent

                            scale: repoMouseArea.pressed ? 0.985 : 1.0
                            opacity: repositoryDelegate.detachSource && root.detachPreviewVisible
                                     ? 1.0 - (root.detachProgress * 0.38)
                                     : 1.0

                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            HoverHandler { id: cardHover }

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

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                spacing: 8

                                // Initial avatar
                                Rectangle {
                                    id: repositoryAvatar
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: width / 2
                                    color: repositoryDelegate.repoColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.repositoryInitial(modelData)
                                        font.family: Style.fontTypes.inter
                                        font.weight: 700
                                        font.pixelSize: 12
                                        color: Style.theme === Style.Light
                                               ? Qt.darker(repositoryDelegate.repoColor, 2.2)
                                               : Qt.lighter(repositoryDelegate.repoColor, 2.2)
                                    }
                                }

                                // Name + current branch
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 1

                                    ScrollingText {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: implicitHeight
                                        text: modelData?.name ?? ""
                                        color: Style.colors.foreground
                                        running: cardHover.hovered
                                        font.family: Style.fontTypes.inter
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 11
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text {
                                            text: Style.icons.gitBranch
                                            font.family: Style.fontTypes.font6Pro
                                            font.pixelSize: 8
                                            color: Style.colors.mutedText
                                        }

                                        ScrollingText {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: implicitHeight
                                            text: repositoryDelegate.branchName
                                            color: Style.colors.mutedText
                                            running: cardHover.hovered
                                            font.family: Style.fontTypes.inter
                                            font.weight: Font.Normal
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                // Status badges (must commit / check / push)
                                RowLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 4
                                    visible: !closeButton.visible

                                    // must commit -> dirty dot
                                    Rectangle {
                                        visible: repositoryDelegate.repoState.dirty
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 7
                                        height: 7
                                        radius: 3.5
                                        color: Style.colors.warning
                                    }

                                    // must check / pull -> behind badge
                                    StateBadge {
                                        visible: repositoryDelegate.repoState.behind > 0
                                        icon: Style.icons.arrowDown
                                        count: repositoryDelegate.repoState.behind
                                        badgeColor: Style.colors.accent
                                    }

                                    // must push -> ahead badge
                                    StateBadge {
                                        visible: repositoryDelegate.repoState.ahead > 0
                                        icon: Style.icons.arrowUp
                                        count: repositoryDelegate.repoState.ahead
                                        badgeColor: Style.colors.notificationSuccessIcon
                                    }
                                }

                                // Close — same styling as before, pinned to the right edge.
                                WindowsButton {
                                    id: closeButton
                                    Material.accent: Style.colors.windowsClose
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: visible ? 20 : 0
                                    radius: 6
                                    visible: cardHover.hovered && root.repositories.length > 1
                                    onClicked: root.repositoryController.closeRepo(modelData.path)
                                    content: Item {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10

                                        Rectangle {
                                            width: 12
                                            height: 2
                                            radius: 1
                                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                                            anchors.centerIn: parent
                                            rotation: 45
                                        }

                                        Rectangle {
                                            width: 12
                                            height: 2
                                            radius: 1
                                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                                            anchors.centerIn: parent
                                            rotation: -45
                                        }
                                    }
                                }
                            }
                        }

                        ToolTip {
                            id: tip
                            parent: card
                            visible: repoMouseArea.containsMouse && !repoMouseArea.pressed
                                     && !root.detachActive
                            delay: 400
                            timeout: 5000
                            text: modelData?.path ?? ""

                            x: (card.width - width) / 2
                            y: -height + 6

                            padding: 6

                            contentItem: Text {
                                text: tip.text
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.defaultPt
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

        // Add button - dashed "Add repo" pill anchored at the bottom
        Rectangle {
            id: addButton
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 6
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.bottomMargin: 4
            height: 30
            radius: 7
            color: addRepoMouse.containsMouse
                   ? Qt.rgba(Style.colors.foreground.r, Style.colors.foreground.g, Style.colors.foreground.b, 0.05)
                   : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            readonly property color lineColor: addRepoMouse.containsMouse ? Style.colors.foreground : Style.colors.mutedText

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 7

                // "+" tile
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: addButton.lineColor

                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: Style.icons.plus
                        font.family: Style.fontTypes.font6Pro
                        font.weight: 400
                        font.pixelSize: 8
                        color: addButton.lineColor
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Add repo"
                    font.family: Style.fontTypes.inter
                    font.weight: Font.Medium
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    color: addButton.lineColor
                    verticalAlignment: Text.AlignVCenter
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
            radius: root.detachPreviewSize / 2
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
                font.family: Style.fontTypes.inter
                font.weight: 700
                font.pixelSize: Style.appFont.xlPt
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
