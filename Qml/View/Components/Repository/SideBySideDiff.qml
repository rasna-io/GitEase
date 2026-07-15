
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

    property var diffModel

    property bool readOnly: false
    property var  textColorizer: null

    property int selectionStart: -1
    property int selectionEnd: -1
    property int selectedSide: DiffView.DiffViewSelectionSide.None

    property real horizontalOffset: 0

    readonly property bool isAdd: diffType === GitDiff.Added
    readonly property bool isDel: diffType === GitDiff.Deleted
    readonly property bool isMod: diffType === GitDiff.Modified
    readonly property bool isUnchanged: diffType === GitDiff.Context
    property bool hasAction: false
    property int selectedFileStatus: -1

    // Guide targets — the stage/revert/stash action buttons, exposed so a GuideController
    // step can spotlight the actual button instead of the whole row.
    readonly property alias stageButton:  stageButton
    readonly property alias revertButton: revertButton
    readonly property alias stashButton:  stashButton

    /* Signals
     * ****************************************************************************************/
    signal requestSplit(int cursorPos, string textAfter)
    signal requestMergeUp()
    signal requestFocusNext()
    signal requestFocusPrev()
    signal requestStage(int start, int end, int type)
    signal requestRevert(int start, int end, int type)
    signal requestStash(int start, int end, int type)
    signal requestTextChange(string newText)

    /* Object Properties
     * ****************************************************************************************/

    // Auto-height based on content
    implicitHeight: Math.max(hasAction ? 90 : 24, Math.max(leftTextMetrics.height, rightTextEdit.contentHeight + 4))

    onIsCurrentItemChanged: {
        if (isCurrentItem && !isDel) {
            Qt.callLater(function() {
                rightTextEdit.forceActiveFocus()
            })
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
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.roboto
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

                    Rectangle {
                        anchors.fill: parent
                        property bool inSelection:
                            (index >= Math.min(delegateRoot.selectionStart, delegateRoot.selectionEnd)) &&
                            (index <= Math.max(delegateRoot.selectionStart, delegateRoot.selectionEnd)) &&
                            selectedSide === DiffView.DiffViewSelectionSide.Left

                        color: inSelection ? Style.colors.accent : "transparent"
                        opacity: 0.8
                    }

                    Text {
                        id: leftDisplay
                        x: -delegateRoot.horizontalOffset
                        text: delegateRoot.textColorizer ? delegateRoot.textColorizer(leftContent) : leftContent
                        textFormat: delegateRoot.textColorizer ? Text.RichText : Text.PlainText
                        color: Style.colors.editorForeground
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.defaultPt
                        topPadding: 2
                        leftPadding: 8
                        TextMetrics { id: leftTextMetrics; text: leftContent; font: leftDisplay.font;}
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
                visible: hasAction && selectedFileStatus !== GitFileStatus.Deleted

                Label {
                    id: stageButton
                    text: Style.icons.plus
                    font.family: Style.fontTypes.font6ProSolid
                    color: stageMsa.containsMouse ? Style.colors.secondaryForeground : Style.colors.secondaryText
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
                    id: revertButton
                    text: Style.icons.arrowRight
                    font.family: Style.fontTypes.font6ProSolid
                    color: revertMsa.containsMouse ? Style.colors.secondaryForeground : Style.colors.secondaryText
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

                Label {
                    id: stashButton
                    text: Style.icons.archive
                    font.family: Style.fontTypes.font6ProSolid
                    color: stashMsa.containsMouse ? Style.colors.secondaryForeground : Style.colors.secondaryText
                    padding: 5
                    background: Rectangle {
                        color: stashMsa.containsMouse ? Style.colors.accent : Qt.darker(Style.colors.linePanelBackgroound, 1.05)
                        radius: 5
                    }

                    MouseArea {
                        id: stashMsa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            let range = getRange()

                            requestStash(range.start, range.end, range.type);
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
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.roboto
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

                    Rectangle {
                        anchors.fill: parent
                        property bool inSelection:
                            (index >= Math.min(delegateRoot.selectionStart, delegateRoot.selectionEnd)) &&
                            (index <= Math.max(delegateRoot.selectionStart, delegateRoot.selectionEnd)) &&
                            selectedSide === DiffView.DiffViewSelectionSide.Right

                        color: inSelection ? Style.colors.accent : "transparent"
                        opacity: 0.8
                    }

                    // Colorized read-only view (shown when plugin active + readOnly)
                    Text {
                        visible: !!delegateRoot.textColorizer && delegateRoot.readOnly
                        x: -delegateRoot.horizontalOffset + 8
                        y: 2
                        text: (delegateRoot.textColorizer && delegateRoot.readOnly)
                              ? delegateRoot.textColorizer(rightContent) : ""
                        textFormat: Text.RichText
                        color: Style.colors.editorForeground
                        font.family: "Cascadia Mono"
                        font.pixelSize: Style.appFont.h3Pt
                    }

                    TextArea {
                        id: rightTextEdit
                        visible: !delegateRoot.textColorizer || !delegateRoot.readOnly
                        x: -delegateRoot.horizontalOffset
                        width: 2000
                        text: rightContent
                        color: Style.colors.editorForeground
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.defaultPt
                        padding: 0
                        leftPadding: 8
                        topPadding: 2
                        selectionColor: Style.colors.accent
                        selectedTextColor: Style.colors.secondaryForeground
                        background: null
                        selectByMouse: true
                        readOnly: delegateRoot.readOnly

                        Material.accent: Style.colors.accent

                        onTextChanged: delegateRoot.requestTextChange(rightTextEdit.text)

                        Keys.onPressed: (event) => {
                                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                event.accepted = true
                                                var pos = cursorPosition
                                                var txtAfter = text.substring(pos)
                                                delegateRoot.requestSplit(pos, txtAfter)
                                            }
                                            else if (event.key === Qt.Key_Up) {
                                                if (cursorRectangle.y <= topPadding + 2) {
                                                    event.accepted = true
                                                    delegateRoot.requestFocusPrev()
                                                }
                                            }
                                            else if (event.key === Qt.Key_Down) {
                                                if (cursorRectangle.y + cursorRectangle.height >= height - bottomPadding) {
                                                    event.accepted = true
                                                    delegateRoot.requestFocusNext()
                                                }
                                            }
                                            else if (event.key === Qt.Key_Backspace) {
                                                if (cursorPosition === 0) {
                                                    event.accepted = true
                                                    delegateRoot.requestMergeUp()
                                                }
                                            }
                                        }
                    }
                }
            }
        }
    }

    function getRange() {
        let startIdx = index;
        let endIdx = index;
        let model = diffModel || fileModel;

        for (let i = index; i < model.count; i++) {
            let item = model.get(i);
            if (!item || item.diffType === GitDiff.Context ||
                (item.rowType && item.rowType !== "diff")) break;
            endIdx = i;
        }

        let firstItem = model.get(startIdx);
        let lastItem = model.get(endIdx);

        if (!firstItem || !lastItem) return { start: 0, end: 0, type: 0 };

        let gitStart = firstItem.oldLineNum > 0 ? firstItem.oldLineNum : firstItem.newLineNum;
        let gitEnd = Math.max(lastItem.oldLineNum, lastItem.newLineNum);

        if (firstItem.diffType === GitDiff.Deleted) {
            gitStart = firstItem.oldLineNum;
        } else if (firstItem.diffType === GitDiff.Added) {
            gitStart = firstItem.newLineNum;
        }

        return { start: gitStart, end: gitEnd, type: firstItem.diffType };
    }
}
