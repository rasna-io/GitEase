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
    property color tagBackColor: Style.colors.popupChipBackground

    /* Signals
     * ****************************************************************************************/
    signal wordsChanged()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 34
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

    RowLayout {
        anchors.fill: parent
        spacing: 4

        ListView {
            Layout.preferredWidth: listModel.count === 0 ? 0 : Math.min(contentWidth, root.width * 0.7)
            Layout.preferredHeight: 24
            Layout.leftMargin: 5
            Layout.alignment: Qt.AlignVCenter
            model: listModel
            orientation: ListView.Horizontal
            spacing: 4
            clip: true
            visible: listModel.count !== 0

            delegate: Rectangle {
                width: contentRow.implicitWidth + 16
                height: 24
                radius: 6
                color: root.tagBackColor
                border.width: 1
                border.color: Style.colors.popupChipBorder

                RowLayout {
                    id: contentRow
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 6
                    spacing: 6

                    Text {
                        text: word
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.popupChipText
                        verticalAlignment: Text.AlignVCenter
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
            Layout.fillHeight: true
            placeholderText: "Type and press Enter..."
            selectByMouse: true
            borderWidth: 0
            focusBorderWidth: 0
            backgroundColor: "transparent"
            baseFontSize: Style.appFont.defaultPt
            minHeight: 30

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
