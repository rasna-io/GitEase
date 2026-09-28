import QtQuick

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * ProfileAvatar
 * Circular avatar showing the first letter(s) of a user's name over an accent color.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string username:       ""
    property string avatarColor:    ""
    property var    levels:         []
    property int    size:           42
    property bool   showLevelBadge: false

    property var    excludeLevels:  []

    readonly property var avatarPalette: [
        "#3B82F6", "#A855F7", "#10B981", "#F97316", "#EC4899", "#F59E0B"
    ]

    readonly property color resolvedColor: root.avatarColor !== ""
                                           ? root.avatarColor
                                           : root.derivedColor(root.username)

    readonly property int primaryLevel: {
        if (!root.levels || root.levels.length === 0)
            return -1

        let order = [Config.Local, Config.Global, Config.Worktree, Config.System, Config.App]
        for (let i = 0; i < order.length; i++) {
            if (root.excludeLevels.indexOf(order[i]) !== -1)
                continue
            if (root.levels.indexOf(order[i]) !== -1)
                return order[i]
        }
        return -1
    }

    readonly property bool hasLevel: root.primaryLevel !== -1
    readonly property color levelBadgeColor: root.levelColor(root.primaryLevel)

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth:  root.size
    implicitHeight: root.size

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.resolvedColor

        Text {
            anchors.centerIn: parent
            text: root.initialsFor(root.username)
            font.family: Style.fontTypes.inter
            font.pixelSize: Math.round(root.size * 0.4)
            font.weight: 700
            color: "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Config-level dot (bottom-right)
    Rectangle {
        visible: root.showLevelBadge && root.hasLevel
        width: Math.max(10, Math.round(root.size * 0.3))
        height: width
        radius: width / 2
        color: root.levelBadgeColor
        border.width: 2
        border.color: Style.colors.primaryBackground
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -1
        anchors.bottomMargin: -1
    }

    /* Functions
     * ****************************************************************************************/
    function initialsFor(name) {
        let trimmed = (name || "").trim()
        if (trimmed.length === 0)
            return "?"

        let parts = trimmed.split(/\s+/)
        if (parts.length > 1)
            return (parts[0].charAt(0) + parts[1].charAt(0)).toUpperCase()

        return trimmed.charAt(0).toUpperCase()
    }

    function derivedColor(name) {
        let key = name || ""
        let hash = 0
        for (let i = 0; i < key.length; i++) {
            hash = (hash * 31 + key.charCodeAt(i)) >>> 0
        }
        return root.avatarPalette[hash % root.avatarPalette.length]
    }

    function levelColor(level) {
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
