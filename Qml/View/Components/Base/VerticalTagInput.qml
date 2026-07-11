import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * VerticalTagInput
 *
 * Allows users to add tags by pressing Enter in the text field.
 * Tags can be removed by clicking the x button.
 ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string tagBackColor: "#1f1f1f"
    property string placeHolderText: "Add word..."

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: column.implicitHeight + 16
    color: Style.colors.secondaryBackground
    radius: 5

    /* Children
     * ****************************************************************************************/
    ListModel {
        id: listModel
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        spacing: 0

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            model: listModel
            spacing: 5
            clip: true

            visible: count !== 0

            delegate: Rectangle {
                width: listView.width
                height: 30

                radius: 5
                color: root.tagBackColor

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5

                    Text {
                        text: word
                        color: Style.colors.placeholderText
                        verticalAlignment: Text.AlignVCenter

                        Layout.fillWidth: true
                    }

                    ToolButton {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        padding: 0

                        contentItem: Text {
                            text: "×"
                            color: Style.colors.placeholderText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: listModel.remove(index)
                    }
                }
            }
        }

        TextField {
            id: textField

            Layout.fillWidth: true
            Layout.preferredHeight: 30

            placeholderText: root.placeHolderText
            selectByMouse: true

            background: Rectangle {
                color: "transparent"
                radius: 5
            }

            onAccepted: {
                var w = textField.text.trim()
                if (w !== "" ) {
                    for (var i = 0; i < listModel.count; i++) {
                        if (listModel.get(i).word === w) return  // skip duplicates
                    }
                    listModel.append({ word: w })
                    textField.clear()
                }
            }
        }
    }
}