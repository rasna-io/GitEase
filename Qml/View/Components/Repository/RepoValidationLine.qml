import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * RepoValidationLine
 * Green "✓ <strong> <muted>" inline validation row used by the Open local / Clone tabs.
 * ************************************************************************************************/
RowLayout {
    id: root

    property string strong: ""
    property string muted:  ""

    spacing: 6

    Text {
        text: Style.icons.check
        font.family: Style.fontTypes.font6Pro
        font.pixelSize: 10
        color: Style.colors.notificationSuccessIcon
    }

    Text {
        text: root.strong
        font.family: Style.fontTypes.inter
        font.weight: Font.DemiBold
        font.pixelSize: 11
        color: Style.colors.notificationSuccessIcon
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
