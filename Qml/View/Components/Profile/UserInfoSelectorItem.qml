import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UserInfoSelectorItem
 * Modern user profile list item with actions: select, edit, delete
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string username:       ""
    property string email:          ""
    property var    levels:         []
    property bool   isSelected:     false

    /* Signals
     * ****************************************************************************************/
    signal editUser(string username, string email)
    signal deleteUser(string username, string email)
    signal selectForRepository(string username, string email)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: 55
    color: {
        if(hoverHandler.hovered){
            if(isSelected){
                 return Qt.darker(Style.colors.userInfoSelectectedItem, 1.5)
            }else {
                return Style.colors.surfaceLight
            }
        }else{
            if(isSelected){
                 return Style.colors.userInfoSelectectedItem
            }else {
                return Style.colors.secondaryBackground
            }
        }
    }

    radius: 6
    border.color: root.isSelected ? Style.colors.accent : Style.colors.primaryBorder
    border.width: root.isSelected ? 2 : 1

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
        onClicked: {
            root.selectForRepository(root.username, root.email)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.topMargin: 5
        anchors.rightMargin: 10
        anchors.bottomMargin: 5
        spacing: 10

        // User Icon
        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            Layout.alignment: Qt.AlignVCenter
            radius: 21
            color: Style.colors.surfaceMuted

            Text {
                anchors.centerIn: parent
                text: Style.icons.user
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 18
                color: Style.colors.iconOnSurface
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // User Info
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            RowLayout {
                spacing: 6

                Text {
                    text: root.username
                    font.pixelSize: 13
                    font.family: Style.fontTypes.roboto
                    font.weight: 600
                    color: Style.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                }

                // Level Badges
                Repeater {
                    model: root.levels
                    
                    Rectangle {
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: levelText.implicitWidth + 10
                        Layout.alignment: Qt.AlignVCenter
                        radius: 2
                        color: getLevelColor(modelData)

                        Text {
                            id: levelText
                            anchors.centerIn: parent
                            text: getLevelName(modelData)
                            font.pixelSize: 9
                            font.family: Style.fontTypes.roboto
                            font.weight: 300
                            color: Style.colors.secondaryForeground
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Text {
                text: root.email
                font.pixelSize: 11
                font.family: Style.fontTypes.roboto
                color: Style.colors.mutedText
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }
        }

        // Action Buttons
        RowLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: 4
            visible: hoverHandler.hovered || root.isSelected

            ActionIconButton {
                iconText: Style.icons.penToSquare
                tooltip: "Edit profile"
                textColor: Style.colors.foreground
                hoverBackgroundColor: Style.colors.iconOnSurface
                borderColor: Style.colors.primaryBorder
                borderWidth: 1

                onClicked: root.editUser(root.username, root.email)
            }

            ActionIconButton {
                iconText: Style.icons.trash
                tooltip: "Delete profile"
                textColor: Style.colors.error
                borderColor: Style.colors.primaryBorder
                borderWidth: 1

                onClicked: root.deleteUser(root.username, root.email)
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function getLevelName(level) {
        switch(level) {
            case Config.System:   return "System"
            case Config.Global:   return "Global"
            case Config.Local:    return "Local"
            case Config.Worktree: return "Worktree"
            case Config.App:      return "App"
            default:              return "Unknown"
        }
    }

    function getLevelColor(level) {
        switch(level) {
            case Config.System:   return Qt.darker(Style.colors.addedFile, 1.3)        // System - Green
            case Config.Global:   return Qt.darker(Style.colors.renamedFile, 1.3)      // Global - Cyan
            case Config.Local:    return Qt.darker(Style.colors.modifiediedFile, 1.3)  // Local - Yellow
            case Config.Worktree: return Qt.darker(Style.colors.deletededFile, 1.3)    // Worktree - Red
            case Config.App:      return Qt.darker(Style.colors.untrackedFile, 1.3)    // App - Blue
            default:              return Style.colors.surfaceMuted
        }
    }
}
