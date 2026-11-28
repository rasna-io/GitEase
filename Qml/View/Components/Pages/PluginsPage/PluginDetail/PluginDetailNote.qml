import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailNote
 * One line of explanation under the status chips. It slides open and fades in while there is a
 * note and slides shut when it clears, keeping the last text on screen while it closes.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string text: ""

    property string displayedText: root.text

    readonly property bool shown: root.text !== ""
    property real openProgress: root.shown ? 1.0 : 0.0

    /* Object Properties
     * ****************************************************************************************/
    visible: root.openProgress > 0
    implicitHeight: noteLabel.implicitHeight * root.openProgress
    clip: true

    Behavior on openProgress {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    onTextChanged: {
        if(root.text !== "") {
            root.displayedText = root.text
        }
    }

    /* Children
     * ****************************************************************************************/
    Label {
        id: noteLabel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: (1.0 - root.openProgress) * -Style.dp(6)
        opacity: root.openProgress
        text: root.displayedText
        color: Style.colors.pluginCardMetaText
        font.pixelSize: Style.appFont.smallPt
        font.family: Style.fontTypes.inter
        wrapMode: Text.WordWrap
    }
}
