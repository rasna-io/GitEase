import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * Header
 * Root is an Item with a ColumnLayout and a MouseArea (dragArea) that acts as the window
 * handle when the header is dragged or double-clicked.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property Component content

    /* Children
     * ****************************************************************************************/
    MouseArea {

        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: WindowController.startSystemMove()
        onDoubleClicked: WindowController.toggleMaxRestore()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 0

            Item {
                Layout.preferredWidth: 120

                Image {
                    anchors.centerIn: parent
                    width: 99
                    height: 28
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/GitEase/Resources/Images/Logo.svg"
                }
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent: root.content
            }

            WindowsHeader {
                Layout.preferredWidth: 120
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            Layout.rightMargin: 4
            Layout.leftMargin: 4

            color: Style.colors.accent
            radius: 3
        }
    }
}
