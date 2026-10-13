import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*! ***********************************************************************************************
 * PaletteLibraryPanel
 * Left side of the page: the saved palettes, and the actions that create, store and move them
 * (new, save, import, export).
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    //! Saved palettes: [{ name, base, colors, count }].
    property var    palettes: []

    //! Base themes, to label each palette with the name of its base: [{ key, label }].
    property var    themes: []

    //! Name of the palette being edited; empty for an untitled one.
    property string activePaletteName: ""

    //! Text of the name field.
    property string saveName: ""

    //! Whether a palette is installed. Saving, exporting and "New" need one.
    property bool   paletteActive: false

    /* Signals
     * ****************************************************************************************/
    signal saveNameEdited(string name)
    signal paletteSelected(var palette)
    signal paletteDeleteRequested(string name)
    signal newRequested()
    signal saveRequested()
    signal importRequested()
    signal exportRequested()

    /* Functions
     * ****************************************************************************************/
    function baseLabelOf(baseKey) {
        for(const theme of root.themes) {
            if(theme.key === baseKey) {
                return theme.label
            }
        }
        return baseKey.length > 0 ? baseKey : "Light"
    }

    function nameExists(name) {
        const wanted = name.trim().toLowerCase()
        for(const palette of root.palettes) {
            if(palette.name.toLowerCase() === wanted) {
                return true
            }
        }
        return false
    }

    /* Object Properties
     * ****************************************************************************************/
    color: root.chrome.panel

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: root.chrome.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "LIBRARY"
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeMicro
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                color: root.chrome.textFaint
            }

            PalettoButton {
                chrome: root.chrome
                text: "New"
                variant: "ghost"
                iconText: "" // plus
                enabled: root.paletteActive
                tooltip: "Start again from the base theme"
                onClicked: root.newRequested()
            }
        }

        ListView {
            id: paletteList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 3
            model: root.palettes
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: PalettoScrollBar {}

            delegate: PaletteRow {
                id: paletteDelegate

                required property var modelData

                chrome: root.chrome
                width: ListView.view.width
                paletteName: paletteDelegate.modelData.name
                baseLabel: root.baseLabelOf(paletteDelegate.modelData.base)
                changes: paletteDelegate.modelData.count
                current: root.paletteActive
                         && root.activePaletteName.toLowerCase() === paletteDelegate.modelData.name.toLowerCase()

                onClicked: root.paletteSelected(paletteDelegate.modelData)
                onDeleteRequested: root.paletteDeleteRequested(paletteDelegate.modelData.name)
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 24
                visible: root.palettes.length === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "No saved palettes yet.\nChange a color, name it below and press Save.\nSaved palettes can be chosen in Settings > Appearance."
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeCaption
                color: root.chrome.textFaint
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.chrome.border
        }

        PalettoTextField {
            chrome: root.chrome
            Layout.fillWidth: true
            placeholderText: "Palette name"
            text: root.saveName
            onTextEdited: root.saveNameEdited(text)
            onAccepted: root.saveRequested()
        }

        PalettoButton {
            chrome: root.chrome
            Layout.fillWidth: true
            variant: "primary"
            iconText: "" // floppy-disk
            text: root.nameExists(root.saveName) ? "Update palette" : "Save palette"
            enabled: root.paletteActive && root.saveName.trim().length > 0
            onClicked: root.saveRequested()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PalettoButton {
                chrome: root.chrome
                Layout.fillWidth: true
                text: "Import"
                iconText: "" // download
                tooltip: "Load a .paletto.json file"
                onClicked: root.importRequested()
            }

            PalettoButton {
                chrome: root.chrome
                Layout.fillWidth: true
                text: "Export"
                iconText: "" // upload
                enabled: root.paletteActive
                tooltip: "Save the current palette as a .paletto.json file"
                onClicked: root.exportRequested()
            }
        }
    }
}
