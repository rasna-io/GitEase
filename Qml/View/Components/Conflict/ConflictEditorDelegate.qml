import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictEditorDelegate
 * ************************************************************************************************/

Item {
    id: rowRoot

    /* Property Declarations
     * ****************************************************************************************/
    property bool isCurrentItem     : ListView.isCurrentItem
    property real horizontalOffset  : 0

    readonly property bool isButtonRow  : model.type === "blockButton"
    readonly property bool isBlockLine  : model.type === "blockLine"
    readonly property bool isMarker     : isBlockLine && (model.role === "marker-start" ||
                                                          model.role === "separator"    ||
                                                          model.role === "marker-end")

    /* Signals
     * ****************************************************************************************/
    signal splitRequested(int cursorPos)
    signal mergeUpRequested()
    signal acceptBlockRequested(int blockIndex, string mode)
    signal moveFocusUp()
    signal moveFocusDown()

    /* Object Properties
     * ****************************************************************************************/
    width: parent.width
    height: Math.max(isButtonRow ? 32 : 24,
                     isButtonRow ? buttonRow.implicitHeight + 8 : lineEditor.contentHeight + 4)

    onIsCurrentItemChanged: {
        if (isCurrentItem && !isButtonRow && !isMarker)
            lineEditor.forceActiveFocus()
    }

    Row {
        anchors.fill: parent
        spacing: 0

        // Line number panel
        Label {
            width: 45
            height: parent.height
            text: isButtonRow ? "" : model.lineNumber
            color: Style.colors.linePanelForeground
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.mediumPt
            horizontalAlignment: Text.AlignRight
            rightPadding: 10
            topPadding: 4

            background: Rectangle {
                color: Style.colors.linePanelBackgroound
            }
        }

        // Content panel
        Item {
            id: contentPanel
            height: parent.height
            width: parent.width - 45
            clip: true

            Rectangle {
                anchors.fill: parent
                z: -1
                color: {
                    if (isButtonRow)
                        return Style.colors.secondaryBackground

                    if (!isBlockLine)
                        return "transparent"

                    switch (model.role) {
                    case "marker-start":
                        return Style.colors.conflictMarkerStartBg
                    case "ours":
                        return Style.colors.conflictOursBg
                    case "theirs":
                        return Style.colors.conflictTheirsBg
                    case "marker-end":
                        return Style.colors.conflictMarkerEndBg
                    case "separator":
                        return Style.colors.conflictSeparatorBg
                    default:
                        return "transparent"
                    }
                }
            }

            // 1. Read-only Label exclusively for markers
            Label {
                visible: isMarker
                x: -horizontalOffset
                width: 2000

                color: Style.colors.conflictMarkerText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.h3Pt
                padding: 0
                leftPadding: 8
                topPadding: 2

                text: {
                    switch(model.role){
                        case "marker-start":{
                            let branchName = model.text.replace("<<<<<<<", "").trim()
                            return "Current Change (" + (branchName || "HEAD") + ")"
                        }

                        case "marker-end":{
                            let branchName = model.text.replace(">>>>>>>", "").trim()
                            return "Incoming Change (" + branchName + ")"
                        }

                        case "separator":
                            return "======================="

                        default:
                            return ""
                    }
                }
            }

            // 2. Editable TextArea exclusively for actual code
            TextArea {
                id: lineEditor
                visible: !isButtonRow && !isMarker
                x: -horizontalOffset
                width: 2000

                text: model.text

                color: Style.colors.editorForeground
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.h3Pt
                padding: 0
                leftPadding: 8
                topPadding: 2
                selectionColor: Style.colors.accent
                selectedTextColor: Style.colors.secondaryForeground
                background: null
                selectByMouse: true
                wrapMode: TextArea.NoWrap

                Material.accent: Style.colors.accent

                onTextChanged: {
                    if (!isMarker && !isButtonRow && model.text !== text)
                        model.text = text
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        event.accepted = true
                        splitRequested(cursorPosition)
                    } else if (event.key === Qt.Key_Up) {
                        if (cursorRectangle.y <= topPadding + 2) {
                            event.accepted = true
                            moveFocusUp()
                        }
                    } else if (event.key === Qt.Key_Down) {
                        if (cursorRectangle.y + cursorRectangle.height >= height - bottomPadding) {
                            event.accepted = true
                            moveFocusDown()
                        }
                    } else if (event.key === Qt.Key_Backspace) {
                        if (cursorPosition === 0) {
                            event.accepted = true
                            mergeUpRequested()
                        }
                    }
                }
            }

            // 3. Block buttons
            RowLayout {
                id: buttonRow
                visible: isButtonRow
                anchors.fill: parent
                anchors.margins: 2
                spacing: 8

                Button {
                    text: "Accept Current"
                    flat: true
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 3
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: acceptBlockRequested(model.blockIndex, "ours")
                    }
                }
                Button {
                    text: "Accept Incoming"
                    flat: true
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 3
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: acceptBlockRequested(model.blockIndex, "theirs")
                    }
                }
                Button {
                    text: "Accept Both"
                    flat: true
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 3
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: acceptBlockRequested(model.blockIndex, "both")
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
