import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * TemplatePreview
 * Collapsible panel with the text of a template. It grows open when \a shown becomes true.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool   shown: false
    property string title: ""
    property string body:  ""

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: shown ? Style.dp(150) : 0
    opacity: shown ? 1 : 0
    visible: Layout.preferredHeight > 0
    clip: true

    radius: Style.dp(8)
    color: Style.colors.controlBackground
    border.width: 1
    border.color: Style.colors.controlBorder

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.dp(10)
        spacing: Style.dp(6)

        RowLayout {
            Layout.fillWidth: true

            GitignoreLabel {
                Layout.fillWidth: true
                text: "PREVIEW  \u00b7  " + root.title.toUpperCase()
            }

            GitignoreIconAction {
                text: Style.icons.close
                tooltip: "Close the preview"
                onClicked: root.closeRequested()
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: bodyText.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar {}

            Text {
                id: bodyText
                width: parent.width - Style.dp(10)
                text: root.body
                wrapMode: Text.WrapAnywhere
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.pluginCardDescription
            }
        }
    }
}
