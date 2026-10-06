import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictConfirmationDialog
 * Asks how to go on before conflicted work is staged, saved or thrown away. Offers up to three
 * choices: save (primary), abort (destructive) and cancel; each choice's description is shown as
 * its button's tooltip. The user has to pick one: Escape and clicks outside are ignored, and the
 * close button counts as cancel.
 * Created on demand, and destroys itself once closed.
 * ************************************************************************************************/

PopupDialog {
    id: dialog

    /* Property Declarations
     * ****************************************************************************************/
    property string message             : "There are unsaved modifications!\nDo you want to save your changes?"

    property string saveTitle           : "Save"
    property string saveDescription     : "The modifications will be saved"

    property string acceptTitle         : "Abort Operation"
    property string acceptDescription   : "Discard all changes and exit"

    property string quitTitle           : "Quit Operation"
    property string quitDescription     : "Stop here and leave HEAD, the index and every file exactly as they are"

    property string cancelTitle         : "Keep Resolving"
    property string cancelDescription   : "Return to the conflict editor"

    property bool hasAbort              : true

    property bool hasSave               : false

    /* Signals
     * ****************************************************************************************/
    signal saved()
    signal aborted()
    signal cancelled()

    /* Object Properties
     * ****************************************************************************************/
    modal: true
    focus: true
    width: 480
    closePolicy: Popup.NoAutoClose

    title: "Save modifications"
    iconText: Style.icons.warning
    iconColor: dialog.hasAbort ? Style.colors.error : Style.colors.warning

    onCloseButtonClicked: dialog.cancelled()

    onClosed: destroy()

    /* Children
     * ****************************************************************************************/
    Text {
        Layout.fillWidth: true

        text: dialog.message
        textFormat: Text.PlainText
        color: Style.colors.popupBodyText
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        lineHeight: 1.2
        wrapMode: Text.WordWrap
    }

    actions: [
        PopupButton {
            text: dialog.cancelTitle
            tooltip: dialog.cancelDescription
            onClicked: {
                dialog.cancelled()
                dialog.close()
            }
        },

        PopupButton {
            visible: dialog.hasAbort
            tone: PopupButton.Destructive
            text: dialog.acceptTitle
            tooltip: dialog.acceptDescription
            onClicked: {
                dialog.aborted()
                dialog.close()
            }
        },

        PopupButton {
            visible: dialog.hasSave
            tone: PopupButton.Primary
            text: dialog.saveTitle
            tooltip: dialog.saveDescription
            onClicked: {
                dialog.saved()
                dialog.close()
            }
        }
    ]
}
