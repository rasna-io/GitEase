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
    property color tagBackColor: Style.colors.popupChipBackground
    property string placeHolderText: "Type and press Enter..."

    /* Signals
     * ****************************************************************************************/
    signal wordsChanged()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: column.implicitHeight + 10
    color: tagHover.hovered && !textField.activeFocus ? Style.colors.controlBackgroundHover
                                                      : Style.colors.controlBackground
    radius: 7
    border.width: 1
    border.color: textField.activeFocus ? Style.colors.accent
                : tagHover.hovered      ? Style.colors.controlBorderHover
                                        : Style.colors.controlBorder

    Behavior on color { ColorAnimation { duration: Style.motionFast } }
    Behavior on border.color { ColorAnimation { duration: Style.motionFast } }

    HoverHandler { id: tagHover }

    /* Children
     * ****************************************************************************************/
    ListModel {
        id: listModel
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        spacing: 4

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            Layout.leftMargin: 5
            Layout.rightMargin: 5

            model: listModel
            spacing: 4
            clip: true
            interactive: false

            visible: count !== 0

            delegate: Rectangle {
                width: listView.width
                height: 28

                radius: 6
                color: root.tagBackColor
                border.width: 1
                border.color: Style.colors.popupChipBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: word
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.popupChipText
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight

                        Layout.fillWidth: true
                    }

                    Text {
                        text: "\u00d7"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                        color: removeMouse.containsMouse ? Style.colors.error : Style.colors.placeholderText
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            id: removeMouse
                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                listModel.remove(index)
                                root.wordsChanged()
                            }
                        }
                    }
                }
            }
        }

        TextField {
            id: textField

            Layout.fillWidth: true
            Layout.preferredHeight: 28

            placeholderText: root.placeHolderText
            selectByMouse: true
            borderWidth: 0
            focusBorderWidth: 0
            backgroundColor: "transparent"
            baseFontSize: Style.appFont.defaultPt
            minHeight: 28

            onAccepted: {
                var w = textField.text.trim()
                if (w !== "" ) {
                    for (var i = 0; i < listModel.count; i++) {
                        if (listModel.get(i).word === w) return  // skip duplicates
                    }
                    listModel.append({ word: w })
                    root.wordsChanged()
                    textField.clear()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function getWords() {
        var result = []
        for (var i = 0; i < listModel.count; i++)
            result.push(listModel.get(i).word)
        return result
    }

    function setWords(words) {
        listModel.clear()
        for (var i = 0; i < words.length; i++)
            if(words[i].length > 0) listModel.append({ word: words[i] })
    }
}
