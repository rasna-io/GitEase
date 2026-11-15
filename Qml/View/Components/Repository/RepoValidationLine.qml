import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * RepoValidationLine
 * "✓ <strong> <muted>" inline validation row used by the Open local / Clone tabs. Green when `valid`,
 * red with a warning icon otherwise.
 * ************************************************************************************************/
RowLayout {
    id: root

    property string strong: ""
    property string muted:  ""
    property bool   valid:  true

    readonly property color accentColor: root.valid ? Style.colors.notificationSuccessIcon
                                                    : Style.colors.notificationErrorIcon

    spacing: 6

    Text {
        text: root.valid ? Style.icons.check : Style.icons.warning
        font.family: Style.fontTypes.font6Pro
        font.pixelSize: 10
        color: root.accentColor
    }

    Text {
        text: root.strong
        font.family: Style.fontTypes.inter
        font.weight: Font.DemiBold
        font.pixelSize: 11
        color: root.accentColor
    }

    Text {
        visible: text !== ""
        text: root.muted
        font.family: Style.fontTypes.inter
        font.pixelSize: 11
        color: Style.colors.mutedText
    }

    Item {
        Layout.fillWidth: true
    }
}
