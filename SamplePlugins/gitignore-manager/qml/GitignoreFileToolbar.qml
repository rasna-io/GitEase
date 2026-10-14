import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreFileToolbar
 * Title, rule/line count and the Copy / Edit / Discard / Save buttons of the .gitignore card.
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int    ruleCount: 0
    property int    lineCount: 0
    property string eol:       ""
    property bool   editing:   false
    property bool   dirty:     false
    property bool   canCopy:   false

    /* Signals
     * ****************************************************************************************/
    signal copyRequested()
    signal editRequested()
    signal discardRequested()
    signal saveRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing: Style.dp(8)

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        GitignoreLabel {
            Layout.fillWidth: true
            text: ".GITIGNORE"
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.ruleCount + (root.ruleCount === 1 ? " rule" : " rules") + "  \u00b7  " + root.lineCount
                  + (root.lineCount === 1 ? " line" : " lines") + "  \u00b7  " + root.eol
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.microPt
            color: Style.colors.pluginCardMetaText
        }
    }

    GitignoreButton {
        visible: !root.editing
        iconText: Style.icons.copy
        tooltip: "Copy the file"
        enabled: root.canCopy
        onClicked: root.copyRequested()
    }

    GitignoreButton {
        visible: !root.editing
        iconText: Style.icons.edit
        text: "Edit"
        onClicked: root.editRequested()
    }

    GitignoreButton {
        visible: root.editing
        text: "Discard"
        onClicked: root.discardRequested()
    }

    GitignoreButton {
        visible: root.editing
        variant: "primary"
        iconText: Style.icons.check
        text: "Save"
        enabled: root.dirty
        onClicked: root.saveRequested()
    }
}
