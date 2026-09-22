import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * MergeMethodPopup
 * ************************************************************************************************/


IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string sourceBranch: ""
    property string targetBranch: ""

    readonly property var mergeMethods: [
        {
            id: 0,
            title: "Merge commit",
            description: "Creates a merge commit preserving full history. Fast-forward if possible.",
            command: GitCommandText.merge(root.sourceBranch, false)
        },
        {
            id: 1,
            title: "Merge commit (no fast-forward)",
            description: "Always creates a merge commit even if fast-forward is possible.",
            command: GitCommandText.merge(root.sourceBranch, true)
        }
    ]

    property int selectedMethod: 0
    property bool deleteBranchAfterMerge: false
    property bool pushToRemoteAfterMerge: false

    /* signals
     * ****************************************************************************************/
    signal accepted(bool noFF, bool deleteBranch, bool pushRemote)

    /* Object Properties
     * ****************************************************************************************/
    width: 480
    height: contentRoot.implicitHeight
    padding: 0

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        id: contentRoot

        implicitWidth: root.width
        implicitHeight: contentCol.implicitHeight + 2

        color: Style.colors.primaryBackground
        radius: 10
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            id: contentCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1

            spacing: 0

            // ── Header ───────────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: headerRow.implicitHeight + 24
                color: "transparent"

                RowLayout {
                    id: headerRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 20
                    anchors.rightMargin: 12

                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Merge Branch"
                        color: Style.colors.titleText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.h3Pt
                        font.weight: 700
                        elide: Text.ElideRight
                    }

                    // Close button (same idiom as RebasePlanHeader)
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: Style.dp(26)
                        Layout.preferredHeight: Style.dp(26)

                        radius: 4
                        color: closeHover.hovered ? Style.colors.cardBackground : "transparent"

                        HoverHandler {
                            id: closeHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: root.close()
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Style.icons.close
                            color: closeHover.hovered ? Style.colors.foreground : Style.colors.mutedText
                            font.family: Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: Style.appFont.mediumPt
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Style.colors.secondaryBorder
                }
            }

            // ── Body ─────────────────────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.topMargin: 14

                spacing: 14

                // Caption: "Merging source → target"
                RowLayout {
                    Layout.fillWidth: true

                    spacing: 4

                    Text {
                        text: "Merging"
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    Text {
                        Layout.maximumWidth: 180
                        text: root.sourceBranch
                        color: Style.colors.accent
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                        font.weight: 600
                        elide: Text.ElideRight
                    }

                    Text {
                        text: Style.icons.arrowRight
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.targetBranch
                        color: Style.colors.foreground
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                        font.weight: 600
                        elide: Text.ElideRight
                    }
                }

                // ── Method cards ─────────────────────────────────────────────────────
                Repeater {
                    model: root.mergeMethods

                    delegate: Rectangle {
                        id: methodCard

                        required property var modelData

                        readonly property bool isSelected: root.selectedMethod === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: cardCol.implicitHeight + 24

                        radius: 8
                        color: isSelected ? Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.08)
                                          : methodCardMouse.containsMouse ? Style.colors.controlBackgroundHover
                                                                          : Style.colors.controlBackground
                        border.width: 1
                        border.color: isSelected ? Style.colors.accent : methodCardMouse.containsMouse ? Style.colors.controlBorderHover
                                                                                                       : Style.colors.controlBorder

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
                        }

                        MouseArea {
                            id: methodCardMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedMethod = methodCard.modelData.id
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            spacing: 12

                            // Radio indicator
                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 2

                                width: 16
                                height: 16
                                radius: 8

                                color: methodCard.isSelected ? Style.colors.accent : "transparent"
                                border.width: methodCard.isSelected ? 0 : 2
                                border.color: methodCardMouse.containsMouse ? Style.colors.controlBorderHover : Style.colors.mutedText

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }

                            ColumnLayout {
                                id: cardCol

                                Layout.fillWidth: true

                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    text: methodCard.modelData.title
                                    color: Style.colors.foreground
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.weight: 600
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: methodCard.modelData.description
                                    color: Style.colors.mutedText
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.smallPt
                                    wrapMode: Text.WordWrap
                                }

                                // Git command preview inside a card
                                CommandPreview {
                                    Layout.topMargin: 4
                                    Layout.fillWidth: true

                                    command: methodCard.modelData.command
                                    copyable: false
                                }
                            }
                        }
                    }
                }

                // ── Post-merge options ───────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 10

                    Repeater {
                        model: [
                            { key: "delete", label: "Delete branch after merge" },
                            { key: "push",   label: "Push to remote after merge" }
                        ]

                        delegate: CheckBox {
                            id: optionRow

                            required property var modelData

                            readonly property bool isChecked: modelData.key === "delete"
                                                              ? root.deleteBranchAfterMerge
                                                              : root.pushToRemoteAfterMerge

                            Layout.fillWidth: true

                            text: modelData.label
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt

                            checkable: false
                            checked: isChecked
                            hoverEnabled: true

                            onClicked: {
                                if (optionRow.modelData.key === "delete")
                                    root.deleteBranchAfterMerge = !root.deleteBranchAfterMerge
                                else
                                    root.pushToRemoteAfterMerge = !root.pushToRemoteAfterMerge
                            }
                        }
                    }
                }

            }

            // ── Footer ───────────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: footerRow.implicitHeight + 20
                color: Style.colors.secondaryBackground

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: Style.colors.secondaryBorder
                }

                RowLayout {
                    id: footerRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20

                    spacing: 8

                    Item { Layout.fillWidth: true }

                    ConflictPillButton {
                        Layout.preferredHeight: Style.dp(25)
                        text: "Cancel"
                        accentColor: Style.colors.mutedText
                        onClicked: root.close()
                    }

                    ConflictPillButton {
                        Layout.preferredHeight: Style.dp(25)
                        text: "Merge " + root.sourceBranch
                        trailingText: Style.icons.arrowRight
                        accentColor: Style.colors.accent
                        prominent: true
                        onClicked: {
                            root.accepted(root.selectedMethod === 1,
                                          root.deleteBranchAfterMerge,
                                          root.pushToRemoteAfterMerge)
                            root.close()
                        }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    onAboutToHide: {
        selectedMethod = 0
        deleteBranchAfterMerge = false
        pushToRemoteAfterMerge = false
    }
}
