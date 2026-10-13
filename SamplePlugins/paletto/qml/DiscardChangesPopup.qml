import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*! ***********************************************************************************************
 * DiscardChangesPopup
 * Asks before an action replaces colors that were not saved. Emits discardConfirmed() when the
 * user agrees; cancelling only closes the popup.
 * ************************************************************************************************/
Popup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    /* Signals
     * ****************************************************************************************/
    signal discardConfirmed()

    /* Object Properties
     * ****************************************************************************************/
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    modal: true
    dim: true
    padding: 20
    width: Math.min(380, (Overlay.overlay ? Overlay.overlay.width : 380) - 32)
    closePolicy: Popup.CloseOnEscape

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        radius: 12
        color: root.chrome.panel
        border.width: 1
        border.color: root.chrome.borderStrong
    }

    contentItem: ColumnLayout {
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: "Discard unsaved changes?"
            font.family: root.chrome.fontText
            font.pixelSize: root.chrome.sizeTitle
            font.weight: Font.DemiBold
            color: root.chrome.text
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "The colors you changed are not saved to your library. Save them first if you want to keep them."
            font.family: root.chrome.fontText
            font.pixelSize: root.chrome.sizeBody
            color: root.chrome.textDim
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            PalettoButton {
                chrome: root.chrome
                text: "Cancel"
                onClicked: root.close()
            }

            PalettoButton {
                chrome: root.chrome
                text: "Discard changes"
                variant: "danger"
                onClicked: {
                    root.discardConfirmed()
                    root.close()
                }
            }
        }
    }
}
