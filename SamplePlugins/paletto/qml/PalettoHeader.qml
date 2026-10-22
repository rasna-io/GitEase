import QtQuick
import QtQuick.Layouts

/*! ***********************************************************************************************
 * PalettoHeader
 * Title bar of the page: icon, name, one status line, the base theme switch and the button that
 * hands the application back to its own theme.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    //! Status line under the title.
    property string subtitle: ""

    //! Base themes to choose from: [{ key, label }].
    property var    themes: []

    //! Key of the selected base theme.
    property string baseTheme: ""

    //! The "Use app theme" button only makes sense while the palette is installed.
    property bool   paletteActive: false

    /* Signals
     * ****************************************************************************************/
    signal baseSelected(string key)
    signal useAppThemeRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 68
    color: root.chrome.panel

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: root.chrome.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            radius: 10
            color: root.chrome.rowSelected

            Text {
                anchors.centerIn: parent
                text: "" // palette
                font.family: root.chrome.fontIcons
                font.pixelSize: root.chrome.sizeTitle
                color: root.chrome.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: "Paletto"
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeTitle
                font.weight: Font.DemiBold
                color: root.chrome.text
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                elide: Text.ElideRight
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeCaption
                color: root.chrome.textDim
            }
        }

        Text {
            text: "Base"
            font.family: root.chrome.fontText
            font.pixelSize: root.chrome.sizeCaption
            color: root.chrome.textFaint
        }

        PalettoSegmented {
            chrome: root.chrome
            options: root.themes
            currentKey: root.baseTheme
            onSelected: function(key) {
                root.baseSelected(key)
            }
        }

        PalettoButton {
            chrome: root.chrome
            text: "Use app theme"
            iconText: "" // undo
            visible: root.paletteActive
            tooltip: "Switch Paletto off and go back to the theme chosen in Settings"
            onClicked: root.useAppThemeRequested()
        }
    }
}
