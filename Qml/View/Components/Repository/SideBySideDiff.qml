import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * SideBySideDiff
 * ************************************************************************************************/

Item {
    id: delegateRoot


    /* Property Declarations
     * ****************************************************************************************/
    property int diffType
    property string leftContent: ""
    property string rightContent: ""
    property int leftLineNum: -1
    property int rightLineNum: -1
    property bool isCurrentItem: false
    property var fileModel

    property real horizontalOffset: 0

    readonly property bool isAdd: diffType === GitDiff.Added
    readonly property bool isDel: diffType === GitDiff.Deleted
    readonly property bool isMod: diffType === GitDiff.Modified
    readonly property bool isUnchanged: diffType === GitDiff.Context
    readonly property bool hasAction: !isUnchanged && (index === 0 || fileModel.get(index - 1).type === GitDiff.Context)


    /* Signals
     * ****************************************************************************************/
    signal requestSplit(int cursorPos, string textAfter)
    signal requestMergeUp()
    signal requestFocusNext()
    signal requestFocusPrev()
    signal requestStage(int start, int end, int type)
    signal requestRevert(int start, int end, int type)

    /* Object Properties
     * ****************************************************************************************/

    // Auto-height based on content
    height: Math.max(hasAction ? 50 : 24, Math.max(leftTextMetrics.height, rightTextEdit.contentHeight + 4))

    onIsCurrentItemChanged: {
        if (isCurrentItem && !isDel) {
            rightTextEdit.forceActiveFocus()
        }
    }



    /* Children
     * ****************************************************************************************/

    RowLayout {
        anchors.fill: parent
        spacing: 0

        /**
          * Left Pane
          * Original Content
          * Read Only
          */
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width / 2
            color: (isDel || isMod) ? Style.colors.diffRemovedBg : "transparent"
            clip: true

            StripedBackground {
                anchors.fill: parent
                visible: isAdd
                stripeColor: Style.colors.voidStripe
            }

            Row {
                anchors.fill: parent
                spacing: 0

                // Line Number
                Label {
                    width: 45
                    height: parent.height
                    text: (leftLineNum > 0) ? leftLineNum : ""
                    color: Style.colors.linePanelForeground
                    font.family: "Cascadia Mono"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    rightPadding: 10
                    topPadding: 4

                    background: Rectangle {
                        color: Style.colors.linePanelBackgroound
                    }
                }

                Item {
                    height: parent.height
                    width: parent.width - 45
                    clip: true

                    Text {
                        id: leftDisplay
                        x: -delegateRoot.horizontalOffset
                        text: leftContent
                        color: Style.colors.editorForeground
                        font.family: "Cascadia Mono"
                        font.pixelSize: 13
                        topPadding: 2
                        leftPadding: 8
                        TextMetrics { id: leftTextMetrics; text: leftDisplay.text; font: leftDisplay.font;}

                    }
                }
            }
        }

        /**
          * CENTER GUTTE
          */
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            color: Style.colors.surfaceLight
            visible: !isUnchanged // Only show for changes
            z: 3

            Rectangle {
                width: 2
                color: Style.colors.surfaceMuted
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                visible: !isUnchanged
            }

            ColumnLayout {

                anchors.centerIn: parent
                visible: hasAction

                Label {
                    text: Style.icons.plus
                    font.family: Style.fontTypes.font6ProSolid
                    color: stageMsa.containsMouse ? Style.colors.secondaryForeground : Qt.darker(Style.colors.linePanelBackgroound, 1.4)
                    padding: 5
                    background: Rectangle {
                        color: stageMsa.containsMouse ? Style.colors.accent : Qt.darker(Style.colors.linePanelBackgroound, 1.05)
                        radius: 5
                    }

                    MouseArea {
                        id: stageMsa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            let range = getRange()

                            requestStage(range.start, range.end, range.type);
                        }
                    }
                }



                Label {
                    text: Style.icons.arrowRight
                    font.family: Style.fontTypes.font6ProSolid
                    color: revertMsa.containsMouse ? Style.colors.secondaryForeground : Qt.darker(Style.colors.linePanelBackgroound, 1.4)
                    padding: 5
                    background: Rectangle {
                        color: revertMsa.containsMouse ? Style.colors.accent : Qt.darker(Style.colors.linePanelBackgroound, 1.05)
                        radius: 5
                    }

                    MouseArea {
                        id: revertMsa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            let range = getRange()

                            requestRevert(range.start, range.end, range.type);
                        }
                    }
                }

            }
        }


        /**
          * Right Pane
          * New Content
          * Editable
          */
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: (isAdd || isMod) ? Style.colors.diffAddedBg : "transparent"
            clip: true

            StripedBackground {
                anchors.fill: parent
                visible: isDel
                stripeColor: Style.colors.voidStripe
            }


            Row {
                anchors.fill: parent
                spacing: 0
                visible: !isDel

                // Line Number
                Label {
                    width: 45
                    height: parent.height
                    z: 2
                    text: (rightLineNum > 0) ? rightLineNum : ""
                    color: Style.colors.linePanelForeground
                    font.family: "Cascadia Mono"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    rightPadding: 10
                    topPadding: 4

                    background: Rectangle {
                        color: Style.colors.linePanelBackgroound
                    }
                }

                Item {
                    height: parent.height
                    width: parent.width - 45
                    clip: true
                    TextArea {
                        id: rightTextEdit
                        x: -delegateRoot.horizontalOffset
                        width: 2000
                        text: rightContent
                        color: Style.colors.editorForeground
                        font.family: "Cascadia Mono"
                        font.pixelSize: 13
                        padding: 0
                        leftPadding: 8
                        topPadding: 2

                        background: null
                        selectByMouse: true

                        Keys.onPressed: (event) => {
                                            // Enter Key -> Split Line
                                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                event.accepted = true
                                                var pos = cursorPosition
                                                var txtAfter = text.substring(pos)
                                                delegateRoot.requestSplit(pos, txtAfter)
                                            }
                                            // Up Arrow -> Go to prev row
                                            else if (event.key === Qt.Key_Up) {
                                                // If on first line of wrapped text, move up
                                                if (cursorRectangle.y <= topPadding + 2) {
                                                    event.accepted = true
                                                    delegateRoot.requestFocusPrev()
                                                }
                                            }
                                            // Down Arrow -> Go to next row
                                            else if (event.key === Qt.Key_Down) {
                                                // If on last line of wrapped text
                                                if (cursorRectangle.y + cursorRectangle.height >= height - bottomPadding) {
                                                    event.accepted = true
                                                    delegateRoot.requestFocusNext()
                                                }
                                            }
                                            // Backspace at start -> Merge Up
                                            else if (event.key === Qt.Key_Backspace) {
                                                if (cursorPosition === 0) {
                                                    event.accepted = true
                                                    delegateRoot.requestMergeUp()
                                                }
                                            }
                                        }

                        onEditingFinished: {
                            // TODO save changes
                        }
                    }
                }
            }
        }
    }


    function getRange() {
        let startIdx = index;
        let endIdx = index;

        // Look ahead to find the end of the consecutive change block
        for (var i = index; i < fileModel.count; i++) {
            if (fileModel.get(i).type !== GitDiff.Context) {
                endIdx = i;
            } else {
                break;
            }
        }

        let firstItem = fileModel.get(startIdx);
        let lastItem = fileModel.get(endIdx);

        let gitStart = firstItem.oldLineNum > 0 ? firstItem.oldLineNum : firstItem.newLineNum;
        let gitEnd = lastItem.oldLineNum > 0 ? lastItem.oldLineNum : lastItem.newLineNum;

        return {start : gitStart, end: gitEnd, type: firstItem.type}
    }
}
