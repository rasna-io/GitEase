import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailSidebar
 * Details, tags and resource links for a plugin. Each row of details is { icon, label, value, mono }.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var   plugin: null
    property var   detailRows: []
    property var   tags: []
    property color tint: Style.colors.accent
    property bool  idCopied: false

    readonly property string pluginId: root.plugin?.pluginId ?? ""

    /* Object Properties
     * ****************************************************************************************/
    spacing: Style.dp(16)

    onPluginIdChanged: {
        root.idCopied = false
        copiedResetTimer.stop()
    }

    /* Functions
     * ****************************************************************************************/
    function copyText(text) {
        if(!text) {
            return
        }

        clipboardHelper.text = text
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        root.idCopied = true
        copiedResetTimer.restart()
    }

    /* Children
     * ****************************************************************************************/
    TextEdit {
        id: clipboardHelper
        visible: false
    }

    Timer {
        id: copiedResetTimer
        interval: 1600

        onTriggered: root.idCopied = false
    }

    PluginDetailCard {
        visible: root.detailRows.length > 0
        title: "Details"

        Repeater {
            model: root.detailRows

            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.dp(10)

                PluginDetailInfoRow {
                    iconText: modelData.icon
                    label: modelData.label
                    value: modelData.value
                    mono: modelData.mono
                }

                Rectangle {
                    visible: index < root.detailRows.length - 1
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Style.colors.pluginCardFooterBorder
                }
            }
        }
    }

    PluginDetailCard {
        visible: root.tags.length > 0
        title: "Tags"

        Flow {
            Layout.fillWidth: true
            spacing: Style.dp(6)

            Repeater {
                model: root.tags

                delegate: PluginDetailChip {
                    text: modelData
                    tint: Style.colors.pluginSectionLabel
                }
            }
        }
    }

    PluginDetailCard {
        visible: root.pluginId !== ""
        title: "Resources"

        PluginDetailLink {
            visible: !!(root.plugin?.githubUrl)
            iconText: Style.icons.globe
            text: "Source repository"
            tint: Style.colors.accent

            onClicked: Qt.openUrlExternally(root.plugin.githubUrl)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.dp(4)

            Label {
                text: "Plugin ID"
                color: Style.colors.pluginCardMetaText
                font.pixelSize: Style.appFont.captionPt
                font.family: Style.fontTypes.inter
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: idRow.implicitHeight + Style.dp(12)
                radius: Style.dp(6)
                color: Style.colors.pluginPageBackground
                border.width: 1
                border.color: Style.colors.pluginCardFooterBorder

                RowLayout {
                    id: idRow
                    anchors.fill: parent
                    anchors.leftMargin: Style.dp(10)
                    anchors.rightMargin: Style.dp(4)
                    spacing: Style.dp(6)

                    Label {
                        Layout.fillWidth: true
                        text: root.pluginId
                        color: Style.colors.pluginCardTitle
                        font.pixelSize: Style.appFont.smallPt
                        font.family: Style.fontTypes.jetBrainsMono
                        elide: Text.ElideMiddle
                    }

                    Button {
                        id: copyIdButton
                        flat: true
                        hoverEnabled: true
                        topInset: 0
                        bottomInset: 0
                        leftInset: 0
                        rightInset: 0
                        padding: Style.dp(6)

                        ToolTip.visible: hovered
                        ToolTip.text: root.idCopied ? "Copied" : "Copy plugin ID"
                        ToolTip.delay: 400

                        background: Rectangle {
                            radius: Style.dp(5)
                            color: copyIdButton.hovered ? Style.colors.pluginSidebarRowHoverBg : "transparent"
                        }

                        contentItem: Text {
                            text: root.idCopied ? Style.icons.check : Style.icons.copy
                            font.family: Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: Style.appFont.captionPt
                            color: root.idCopied ? Style.colors.vibrantMint : Style.colors.pluginSectionLabel
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: root.copyText(root.pluginId)
                    }
                }
            }
        }
    }
}
