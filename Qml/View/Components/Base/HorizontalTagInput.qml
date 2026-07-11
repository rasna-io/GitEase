import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * HorizontalTagInput
 *
 * Allows users to add tags by pressing Enter in the text field.
 * Tags can be removed by clicking the x button.
 ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string tagBackColor: "#1f1f1f"

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.secondaryBackground
    radius: 5

    /* Children
     * ****************************************************************************************/
    ListModel {
        id: listModel
    }

    RowLayout {
        anchors.fill: parent

        ListView {
            Layout.preferredWidth: listModel.count === 0 ? 0 : contentWidth
            Layout.preferredHeight: 30
            Layout.leftMargin: 8
            model: listModel
            orientation: ListView.Horizontal
            spacing: 5
            clip: true
            visible: listModel.count !== 0

            delegate: Rectangle {
                width: contentRow.implicitWidth + 15
                height: 30
                radius: 5
                color: root.tagBackColor

                RowLayout {
                    id: contentRow
                    anchors.fill: parent
                    anchors.margins: 5

                    Text {
                        id: wordText
                        text: word
                        color: Style.colors.placeholderText
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                    }

                    ToolButton {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: 5
                        padding: 0
                        contentItem: Text {
                            text: "x"
                            color: Style.colors.placeholderText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            listModel.remove(index)
                        }
                    }
                }
            }
        }

        TextField {
            id: textField
            Layout.fillWidth: true
            placeholderText: "Add word..."
            selectByMouse: true

            background: Rectangle {
                implicitHeight: 40
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

