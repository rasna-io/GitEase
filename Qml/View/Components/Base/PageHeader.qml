import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * PageHeader
 * Reusable header component with back button, title, and brand
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string pageTitle: ""
    property bool showBackButton: true
    property bool showBrand: true

    /* Signals
     * ****************************************************************************************/
    signal backClicked()

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.bottomMargin: 20
    implicitHeight: 45

    /* Children
     * ****************************************************************************************/
    // Left: Back button
    RoundButton {
        id: backButton
        visible: root.showBackButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: Style.icons.angleLeft
        font.family: Style.fontTypes.font6Pro
        font.pixelSize: 16
        width: 45
        height: 45
        flat: true

        background: Rectangle {
            implicitWidth: 45
            implicitHeight: 45
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Style.colors.accent
        }

        onClicked: root.backClicked()
    }

    // Center: Title - Absolutely centered
    Text {
        anchors.centerIn: parent
        text: root.pageTitle
        visible: text !== ""
        font.pixelSize: 20
        font.bold: true
        font.family: Style.fontTypes.roboto
        font.weight: 400
        color: Style.colors.foreground
        horizontalAlignment: Text.AlignHCenter
    }

    // Right : Logo image
    Image {
        visible: root.showBrand
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        width: 99
        source: "qrc:/GitEase/Resources/Images/Logo.png"
    }

    //! Drag region: we start native move so Snap/AeroShake remain native.
    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: WindowController.startSystemMove()
        onDoubleClicked: WindowController.toggleMaxRestore()
    }
}

