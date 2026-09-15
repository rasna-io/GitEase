import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UserInfoSelectorItem
 * Modern user profile list item with actions: select, edit, delete
 * ************************************************************************************************/
AccentCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string username:       ""
    property string email:          ""
    property var    levels:         []
    property bool   isSelected:     false
    property string avatarColor:    ""

    /* Signals
     * ****************************************************************************************/
    signal editUser(string username, string email)
    signal deleteUser(string username, string email)
    signal selectForRepository(string username, string email)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: contentRow.implicitHeight + 12

    readonly property color cardHoverColor: Style.theme == Style.Light
                                            ? Qt.darker(Style.colors.secondaryBackground, 1.06)
                                            : Qt.lighter(Style.colors.secondaryBackground, 1.6)

    peek: 3
    accentRadius: 9
    cardRadius: 7
    accentColor: avatar.resolvedColor
    cardColor: hoverHandler.hovered ? root.cardHoverColor : Style.colors.secondaryBackground
    cardBorderColor: root.isSelected ? Style.colors.accent : Style.colors.primaryBorder
    cardBorderWidth: 1
    tintColor: Style.colors.userInfoSelectedBackground
    tintVisible: root.isSelected

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hoverHandler
        acceptedDevices: PointerDevice.Mouse
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectForRepository(root.username, root.email)
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.topMargin: 6
        anchors.rightMargin: 10
        anchors.bottomMargin: 6
        spacing: 10

        // User Avatar
        ProfileAvatar {
            id: avatar
            Layout.alignment: Qt.AlignVCenter
            size: 34
            username: root.username
            avatarColor: root.avatarColor
            levels: root.levels
        }

        // User Info
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.username
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.inter
                    font.weight: 700
                    color: Style.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }

                // Level Badges
                Repeater {
                    model: root.levels
                    
                    Rectangle {
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: levelText.implicitWidth + 12
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        color: Qt.rgba(root.getLevelColor(modelData).r,
                                       root.getLevelColor(modelData).g,
                                       root.getLevelColor(modelData).b, 0.18)
                        border.width: 1
                        border.color: Qt.rgba(root.getLevelColor(modelData).r,
                                              root.getLevelColor(modelData).g,
                                              root.getLevelColor(modelData).b, 0.5)

                        Text {
                            id: levelText
                            anchors.centerIn: parent
                            text: root.getLevelName(modelData)
                            font.pixelSize: Style.appFont.captionPt
                            font.family: Style.fontTypes.inter
                            font.weight: 600
                            color: root.getLevelColor(modelData)
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            ScrollingText {
                text: root.email
                font.pixelSize: Style.appFont.smallPt
                font.family: Style.fontTypes.inter
                color: Style.colors.mutedText
                Layout.fillWidth: true
            }

            // Active identity status line
            RowLayout {
                visible: root.isSelected
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: "Active — commits will use this identity"
                    font.pixelSize: Style.appFont.captionPt
                    font.family: Style.fontTypes.inter
                    font.weight: 500
                    color: Style.colors.compatible
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: Style.icons.check
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.compatible
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Action area — active profile shows edit/delete, others show Use + menu
        RowLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: 6

            // Edit / Delete (active profile)
            RowLayout {
                visible: root.isSelected
                spacing: 2

                ActionIconButton {
                    iconText: Style.icons.penToSquare
                    tooltip: "Edit profile"
                    textColor: Style.colors.secondaryText
                    width: 24
                    height: 24

                    onClicked: root.editUser(root.username, root.email)
                }

                ActionIconButton {
                    iconText: Style.icons.trash
                    tooltip: "Delete profile"
                    textColor: Style.colors.error
                    width: 24
                    height: 24

                    onClicked: root.deleteUser(root.username, root.email)
                }
            }

            // Use button (inactive profiles)
            Button {
                visible: !root.isSelected
                Layout.preferredHeight: 26
                Layout.preferredWidth: 46
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 0
                rightPadding: 0

                contentItem: Text {
                    text: "Use"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: 500
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    anchors.fill: parent
                    color: parent.hovered ? Style.colors.controlBackgroundHover : "transparent"
                    radius: 6
                    border.color: Style.colors.controlBorder
                    border.width: 1
                }

                onClicked: root.selectForRepository(root.username, root.email)
            }

            // Overflow menu (inactive profiles)
            ActionIconButton {
                visible: !root.isSelected
                iconText: Style.icons.ellipsisVertical
                tooltip: "More"
                textColor: Style.colors.secondaryText
                width: 24
                height: 24

                onClicked: {
                    overflowMenu.x = width - overflowMenu.width
                    overflowMenu.y = height + 4
                    overflowMenu.open()
                }

                ContextMenu {
                    id: overflowMenu
                    implicitWidth: 150
                    menuModel: [
                        {
                            text: "Edit",
                            icon: Style.icons.penToSquare,
                            action: function() { root.editUser(root.username, root.email) }
                        },
                        {
                            text: "Delete",
                            icon: Style.icons.trash,
                            action: function() { root.deleteUser(root.username, root.email) }
                        }
                    ]
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function getLevelName(level) {
        switch(level) {
            case Config.System:
                return "System"
            case Config.Global:
                return "Global"
            case Config.Local:
                return "Local"
            case Config.Worktree:
                return "Worktree"
            case Config.App:
                return "App"
            default:
                return "Unknown"
        }
    }

    function getLevelColor(level) {
        switch(level) {
            case Config.System:
                return Style.colors.levelSystemBadge
            case Config.Global:
                return Style.colors.levelGlobalBadge
            case Config.Local:
                return Style.colors.levelLocalBadge
            case Config.Worktree:
                return Style.colors.levelWorktreeBadge
            case Config.App:
                return Style.colors.levelAppBadge
            default:
                return Style.colors.surfaceMuted
        }
    }
}
