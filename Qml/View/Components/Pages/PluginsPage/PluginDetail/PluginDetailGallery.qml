import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailGallery
 * Screenshot preview with previous/next arrows and a thumbnail strip.
 * Each screenshot is { url, isGif, caption }.
 * ************************************************************************************************/
PluginDetailCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    screenshots: []
    property string pluginId: ""
    property int    selectedShot: 0

    readonly property bool hasScreenshots: root.screenshots.length > 0
    readonly property var  activeShot: root.hasScreenshots
                                       ? root.screenshots[Math.min(root.selectedShot, root.screenshots.length - 1)]
                                       : null

    /* Object Properties
     * ****************************************************************************************/
    title: "Preview"
    iconText: Style.icons.star
    trailing: root.screenshots.length > 1 ? ((root.selectedShot + 1) + " / " + root.screenshots.length) : ""

    onPluginIdChanged: {
        root.selectedShot = 0
    }

    onScreenshotsChanged: {
        if(root.selectedShot >= root.screenshots.length) {
            root.selectedShot = Math.max(0, root.screenshots.length - 1)
        }
    }

    /* Children
     * ****************************************************************************************/
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(Style.dp(220), Math.min(Style.dp(440), width * 0.56))
        radius: Style.dp(10)
        color: Style.colors.pluginPreviewBackground
        clip: true

        BusyIndicator {
            anchors.centerIn: parent
            running: shotLoader.status === Loader.Loading
                     || (shotLoader.item && shotLoader.item.status === Image.Loading)
            visible: running
        }

        Loader {
            id: shotLoader
            anchors.fill: parent
            anchors.margins: Style.dp(2)
            active: root.hasScreenshots && !!root.activeShot
            sourceComponent: (root.activeShot && root.activeShot.isGif) ? gifShotComponent : imageShotComponent
        }

        Component {
            id: imageShotComponent

            Image {
                source: root.activeShot?.url || ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
            }
        }

        Component {
            id: gifShotComponent

            AnimatedImage {
                source: root.activeShot?.url || ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                playing: true
                cache: true
            }
        }

        PluginDetailGalleryArrow {
            visible: root.screenshots.length > 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Style.dp(10)
            iconText: Style.icons.arrowLeft

            onClicked: {
                root.selectedShot = (root.selectedShot - 1 + root.screenshots.length) % root.screenshots.length
            }
        }

        PluginDetailGalleryArrow {
            visible: root.screenshots.length > 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Style.dp(10)
            iconText: Style.icons.arrowRight

            onClicked: {
                root.selectedShot = (root.selectedShot + 1) % root.screenshots.length
            }
        }

        Rectangle {
            readonly property bool wanted: !!(root.activeShot?.caption) || !!(root.activeShot?.isGif)

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: captionRow.implicitHeight + Style.dp(24)
            visible: wanted

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0, 0, 0, 0)
                }

                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, 0.6)
                }
            }

            RowLayout {
                id: captionRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Style.dp(12)
                spacing: Style.dp(8)

                Label {
                    Layout.fillWidth: true
                    text: root.activeShot?.caption || ""
                    color: "white"
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: !!(root.activeShot?.isGif)
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.18)
                    implicitWidth: gifLabel.implicitWidth + Style.dp(10)
                    implicitHeight: gifLabel.implicitHeight + Style.dp(4)

                    Label {
                        id: gifLabel
                        anchors.centerIn: parent
                        text: "GIF"
                        color: "white"
                        font.pixelSize: Style.appFont.microPt
                        font.weight: Font.DemiBold
                        font.family: Style.fontTypes.inter
                    }
                }
            }
        }
    }

    ListView {
        id: thumbStrip
        visible: root.screenshots.length > 1
        Layout.fillWidth: true
        Layout.preferredHeight: Style.dp(58)
        orientation: ListView.Horizontal
        spacing: Style.dp(8)
        clip: true
        model: root.screenshots
        currentIndex: root.selectedShot
        highlightMoveDuration: 180

        // Keep the selected thumbnail in view when the arrows change the selection

        delegate: Rectangle {
            id: thumb

            readonly property bool selected: index === root.selectedShot

            width: Style.dp(92)
            height: thumbStrip.height
            radius: Style.dp(7)
            color: Style.colors.pluginThumbBackground
            border.width: thumb.selected ? 2 : 1
            border.color: thumb.selected ? root.tint : Style.colors.pluginCardBorder
            opacity: thumb.selected || thumbHover.hovered ? 1.0 : 0.7
            clip: true

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: modelData.url
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: !modelData.isGif
            }

            AnimatedImage {
                anchors.fill: parent
                anchors.margins: 2
                source: modelData.isGif ? modelData.url : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                playing: thumb.selected
                visible: modelData.isGif
            }

            HoverHandler {
                id: thumbHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.selectedShot = index
            }
        }
    }
}
