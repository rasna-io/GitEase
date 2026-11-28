import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import "qrc:/GitEase/Qml/Core/Scripts/PluginDetailFormat.js" as Format

/*! ***********************************************************************************************
 * PluginDetailErrorBanner
 * Slides open below the top bar while there is an error message and slides shut when it clears.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string message: ""

    property string displayedMessage: root.message

    readonly property bool shown: root.message !== ""
    property real openProgress: root.shown ? 1.0 : 0.0

    /* Object Properties
     * ****************************************************************************************/
    visible: root.openProgress > 0
    implicitHeight: (errorRow.implicitHeight + Style.dp(16)) * root.openProgress
    color: Format.withAlpha(Style.colors.softCoralMist, 0.10)
    opacity: root.openProgress
    clip: true

    Behavior on openProgress {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    onMessageChanged: {
        if(root.message !== "") {
            root.displayedMessage = root.message
        }
    }

    /* Children
     * ****************************************************************************************/
    RowLayout {
        id: errorRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Style.dp(8)
        anchors.leftMargin: Style.dp(20)
        anchors.rightMargin: Style.dp(20)
        spacing: Style.dp(10)

        Text {
            text: Style.icons.warning
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.smallPt
            color: Style.colors.softCoralMist
        }

        Label {
            Layout.fillWidth: true
            text: root.displayedMessage
            color: Style.colors.softCoralMist
            font.pixelSize: Style.appFont.smallPt
            font.family: Style.fontTypes.inter
            wrapMode: Text.WordWrap
        }
    }
}
