import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * ConflictAssistSlot
 * Shared advisor strip under the conflict editor. A plugin supplies the body. The host supplies
 * the frame, the title, and the close control.
 * ************************************************************************************************/
Item {
    id: root

    property bool open: false
    property var assist: null
    property string repositoryPath: ""
    property string filePath: ""
    property int regionIndex: -1

    signal applied(string message)
    signal dismissed()
    signal failed(string message)
    signal recommendationChanged(bool ready)

    property bool hasRecommendation: false
    property string recommendationText: ""
    property bool assistBusy: false
    property real accentStrength: 0.45

    function restart() {
        if (!body.item || !root.assist || !body.item.start)
            return
        if (body.source.toString() !== root.assist.url)
            return
        body.item.start()
    }

    function dismissPlugin() {
        if (body.item && body.item.dismiss)
            body.item.dismiss()
    }

    function applyRecommendation() {
        if (body.item && body.item.applyRecommendation)
            body.item.applyRecommendation()
    }

    function pullRecommendation(item) {
        const ready = !!(item && item.hasRecommendation)
        root.hasRecommendation = ready
        root.recommendationText = ready && item.recommendationText ? item.recommendationText : ""
        return ready
    }

    function watchAssist(item) {
        root.pullRecommendation(item)
        root.assistBusy = !!(item && item.busy)
        if (!item)
            return
        if (item.hasRecommendationChanged) {
            item.hasRecommendationChanged.connect(function() {
                const nowReady = root.pullRecommendation(item)
                root.recommendationChanged(nowReady)
                if (nowReady)
                    accentPulse.restart()
            })
        }
        if (item.recommendationTextChanged) {
            item.recommendationTextChanged.connect(function() {
                if (item.hasRecommendation === true)
                    root.recommendationText = item.recommendationText || ""
            })
        }
        if (item.busyChanged) {
            item.busyChanged.connect(function() {
                root.assistBusy = item.busy === true
            })
        }
    }

    function bindAssist(item) {
        if (!item)
            return
        item.repositoryPath = Qt.binding(function() { return root.repositoryPath })
        item.filePath = Qt.binding(function() { return root.filePath })
        item.regionIndex = Qt.binding(function() { return root.regionIndex })
        if (item.applied)
            item.applied.connect(function(message) { root.applied(message) })
        if (item.dismissed)
            item.dismissed.connect(function() { root.dismissed() })
        if (item.failed)
            item.failed.connect(function(message) { root.failed(message) })
        if (item.start)
            item.start()
        root.watchAssist(item)
    }

    clip: true
    implicitHeight: root.open ? Style.dp(220) : 0

    Behavior on implicitHeight {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: accentPulse
        NumberAnimation { target: root; property: "accentStrength"; to: 1; duration: 160 }
        NumberAnimation { target: root; property: "accentStrength"; to: 0.45; duration: 480; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.open || parent.implicitHeight > 1
        color: Style.colors.secondaryBackground

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Style.colors.conflictAssistAccent
            opacity: root.accentStrength

            Rectangle {
                id: busyTrack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.bottom
                height: 2
                color: "transparent"
                clip: true
                visible: root.assistBusy

                Rectangle {
                    id: busyBar
                    y: 0
                    width: busyTrack.width * 0.28
                    height: parent.height
                    color: Style.colors.conflictAssistAccent

                    SequentialAnimation on x {
                        running: root.assistBusy && root.open
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: -busyBar.width
                            to: busyTrack.width
                            duration: 1200
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }

            ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.dp(12)
            anchors.topMargin: Style.dp(8)
            spacing: Style.dp(8)
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(8)

                Text {
                    id: assistStar
                    text: Style.icons.star
                    color: Style.colors.conflictAssistAccent
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.dp(13)
                    transformOrigin: Item.Center

                    SequentialAnimation on scale {
                        running: root.assistBusy && root.open
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.12; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.94; duration: 700; easing.type: Easing.InOutSine }
                        onRunningChanged: if (!running) assistStar.scale = 1
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.assist ? root.assist.title : ""
                    color: Style.colors.conflictAssistAccent
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.dp(13)
                    font.bold: true
                    elide: Text.ElideRight
                }
                ConflictPillButton {
                    text: ""
                    leadingText: Style.icons.close
                    accentColor: Style.colors.mutedText
                    tooltip: qsTr("Close the assistant")
                    onClicked: root.dismissed()
                }
            }

            Loader {
                id: body
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: root.open && root.assist !== null
                source: root.open && root.assist ? root.assist.url : ""
                onLoaded: root.bindAssist(item)
                onItemChanged: if (!item) root.watchAssist(null)
            }
        }
    }
}
