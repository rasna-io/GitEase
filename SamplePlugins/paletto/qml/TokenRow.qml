import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*! ***********************************************************************************************
 * TokenRow
 * One color token: swatch, readable name, technical name, current value and a revert action.
 * ************************************************************************************************/
Rectangle {
    id: root

    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    /* Property Declarations
     * ****************************************************************************************/
    //! Filled from the model roles of the list the row is a delegate of.
    required property string tokenName
    required property string label
    required property string value
    required property bool   changed

    property bool   selected:  false

    /* Signals
     * ****************************************************************************************/
    signal clicked()
    signal revertRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 46
    radius: 8
    color: selected ? root.chrome.rowSelected : hover.hovered ? root.chrome.rowHover : "transparent"

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 12

        // Swatch over a checkerboard so transparent colors are visible
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 7
            color: root.chrome.checkerDark
            border.width: 1
            border.color: root.chrome.borderStrong
            clip: true

            Rectangle {
                width: parent.width / 2
                height: parent.height / 2
                color: root.chrome.checkerLight
            }
            Rectangle {
                x: parent.width / 2
                y: parent.height / 2
                width: parent.width / 2
                height: parent.height / 2
                color: root.chrome.checkerLight
            }
            Rectangle {
                anchors.fill: parent
                color: root.value
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                spacing: 6

                Text {
                    text: root.label
                    elide: Text.ElideRight
                    font.family: root.chrome.fontText
                    font.pixelSize: root.chrome.sizeBody
                    font.weight: Font.Medium
                    color: root.chrome.text
                }

                Rectangle {
                    visible: root.changed
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: root.chrome.accent
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.tokenName
                elide: Text.ElideRight
                font.family: root.chrome.fontMono
                font.pixelSize: root.chrome.sizeMicro
                color: root.chrome.textFaint
            }
        }

        AbstractButton {
            id: revertButton
            visible: root.changed && (hover.hovered || revertButton.hovered)
            implicitWidth: 26
            implicitHeight: 26
            hoverEnabled: true

            background: Rectangle {
                radius: 6
                color: revertButton.hovered ? root.chrome.panelRaised : "transparent"
            }
            contentItem: Text {
                text: "" // undo
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.chrome.fontIcons
                font.pixelSize: root.chrome.sizeCaption
                color: revertButton.hovered ? root.chrome.accent : root.chrome.textDim
            }

            PalettoToolTip {
                visible: revertButton.hovered
                text: "Back to the base theme value"
            }

            onClicked: root.revertRequested()
        }

        Text {
            Layout.preferredWidth: 84
            horizontalAlignment: Text.AlignRight
            text: root.value
            font.family: root.chrome.fontMono
            font.pixelSize: root.chrome.sizeCaption
            color: root.chrome.textDim
        }
    }
}
