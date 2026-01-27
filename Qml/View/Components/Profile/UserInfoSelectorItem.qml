import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UserInfoSelectorItem
 * Modern user profile list item with actions: select as default, edit, delete
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string profileId:      ""
    property string username:       ""
    property string email:          ""
    property int    level:          -1
    property bool   isDefault:      false
    property bool   isSelected:     false

    /* Signals
     * ****************************************************************************************/
    signal selectAsDefault(string profileId)
    signal editUser(string profileId)
    signal deleteUser(string profileId)
    signal selectForRepository(string profileId)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: 62
    color: {
        if(hoverHandler.hovered){
            if(isSelected){
                 return Style.colors.accentHover
            }else {
                return Style.colors.surfaceLight
            }
        }else{
            if(isSelected){
                 return Style.colors.accent
            }else {
                return Style.colors.secondaryBackground
            }
        }
    }

    radius: 6
    border.color: root.isDefault ? Style.colors.warning : Style.colors.primaryBorder
    border.width: (root.isSelected || root.isDefault) ? 2 : 1

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
            root.selectForRepository(root.profileId)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // User Icon
        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            Layout.alignment: Qt.AlignVCenter
            radius: 21
            color: root.isSelected ?
                       Style.colors.accent : (root.isDefault ? Style.colors.defaultBackground : Style.colors.surfaceMuted)

            Text {
                anchors.centerIn: parent
                text: Style.icons.user
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 18
                color: root.isSelected ?
                           Style.colors.primaryBackground : (root.isDefault ? Style.colors.iconOnDefault : Style.colors.iconOnSurface)
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
                    color: root.isSelected ? Style.colors.selectedText : Style.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    visible: root.isDefault
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: defaultText.implicitWidth + 10
                    Layout.alignment: Qt.AlignVCenter
                    radius: 8
                    color: Style.colors.warning

                    Text {
                        id: defaultText
                        anchors.centerIn: parent
                        text: "Default"
                        font.pixelSize: 9
                        font.family: Style.fontTypes.roboto
                        font.weight: 600
                        color: Style.colors.onWarningText
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Level Badge
                Rectangle {
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: levelText.implicitWidth + 10
                    Layout.alignment: Qt.AlignVCenter
                    radius: 8
                    color: getLevelColor(root.level)

                    Text {
                        id: levelText
                        anchors.centerIn: parent
                        text: getLevelName(root.level)
                        font.pixelSize: 9
                        font.family: Style.fontTypes.roboto
                        font.weight: 300
                        color: Style.colors.secondaryForeground
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Text {
                text: root.email
                font.pixelSize: 11
                font.family: Style.fontTypes.roboto
                color: root.isSelected ? Style.colors.selectedText : Style.colors.mutedText
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }
        }

        // Action Buttons
        RowLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: 4
            visible: hoverHandler.hovered || root.isDefault || root.isSelected

            ActionIconButton {
                iconText: Style.icons.star
                tooltip: root.isDefault ? "Default app user" : "Set as default app user"
                textColor: root.isDefault ?
                               Style.colors.warning : root.isSelected ? Style.colors.secondaryForeground : Style.colors.foreground
                backgroundColor: root.isDefault ? Qt.rgba(1, 0.8, 0.4, 0.15) : "transparent"
                borderColor: root.isDefault ? Style.colors.warning : Style.colors.primaryBorder
                hoverBackgroundColor: Style.colors.iconOnSurface
                borderWidth: 1

                onClicked: root.selectAsDefault(root.profileId)
            }

            ActionIconButton {
                iconText: Style.icons.penToSquare
                tooltip: "Edit profile"
                textColor: root.isSelected ? Style.colors.secondaryForeground : Style.colors.foreground
                hoverBackgroundColor: Style.colors.iconOnSurface
                borderColor: Style.colors.primaryBorder
                borderWidth: 1

                onClicked: root.editUser(root.profileId)
            }

            ActionIconButton {
                iconText: Style.icons.trash
                tooltip: "Delete profile"
                textColor: Style.colors.error
                borderColor: Style.colors.primaryBorder
                borderWidth: 1

                onClicked: root.deleteUser(root.profileId)
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
