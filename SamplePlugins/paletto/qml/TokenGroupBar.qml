import QtQuick
import QtQuick.Controls

/*! ***********************************************************************************************
 * TokenGroupBar
 * Horizontal row of chips that filters the token list by group. The first chip, "All", clears
 * the filter.
 * ************************************************************************************************/
ListView {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    //! Names of the groups to offer.
    property var    groups: []

    //! The selected group; empty means all groups.
    property string currentGroup: ""

    /* Signals
     * ****************************************************************************************/
    signal groupSelected(string group)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 30
    orientation: ListView.Horizontal
    spacing: 6
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    model: [""].concat(root.groups)

    delegate: AbstractButton {
        id: chip

        required property string modelData

        readonly property bool current: root.currentGroup === chip.modelData

        implicitHeight: 28
        implicitWidth: chipLabel.implicitWidth + 24
        hoverEnabled: true

        background: Rectangle {
            radius: 14
            color: chip.current ? root.chrome.rowSelected
                 : chip.hovered ? root.chrome.rowHover : "transparent"
            border.width: 1
            border.color: chip.current ? root.chrome.accent : root.chrome.border
        }

        contentItem: Text {
            id: chipLabel
            text: chip.modelData.length > 0 ? chip.modelData : "All"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: root.chrome.fontText
            font.pixelSize: root.chrome.sizeCaption
            color: chip.current ? root.chrome.text : root.chrome.textDim
        }

        onClicked: root.groupSelected(chip.modelData)

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}
