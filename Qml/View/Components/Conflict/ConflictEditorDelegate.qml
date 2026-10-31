import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictEditorDelegate
 *
 *   blockButton              -> card header strip
 *   blockLine "marker-start" -> OURS region label
 *   blockLine "ours"         -> code line, ours tint
 *   blockLine "separator"    -> THEIRS region label
 *   blockLine "theirs"       -> code line, theirs tint
 *   aiPreview "ai-label"     -> AI region label
 *   aiPreview "ai"           -> code line, AI tint
 *   blockLine "marker-end"   -> card action bar
 *   contextLine / resolved   -> plain code line
 *
 * ************************************************************************************************/

Item {
    id: rowRoot

    /* Property Declarations
     * ****************************************************************************************/
    property bool isCurrentItem     : ListView.isCurrentItem
    property real horizontalOffset  : 0

    //! blockIndex -> { ours: <label>, theirs: <label> }, supplied by the editor pane.
    property var  blockLabels       : ({})
    //! Conflicts still open in this file. Shown once, on the first open card.
    property int  openBlockCount    : 0
    //! Index of the first still-open block, so only that card carries the count.
    property int  firstOpenBlock    : -1

    property TextDirectionController textDirectionController: null
    property bool aiAvailable: false
    property string assistLabel: "Ask"
    property bool recommendationReady: false
    property int recommendationBlock: -1

    readonly property bool showAiChoice: rowRoot.recommendationReady
                                         && !rowRoot.isResolved
                                         && rowRoot.blockIndex === rowRoot.recommendationBlock
                                         && rowRoot.recommendationBlock > 0
    property real aiChoiceReveal: rowRoot.showAiChoice ? 1 : 0

    Behavior on aiChoiceReveal { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    readonly property int    blockIndex    : model.blockIndex || 0
    readonly property string blockRole     : model.role || ""
    readonly property int    resolvedGroup : model.resolvedGroup || 0
    readonly property int    cardNumber    : model.cardNumber || 0
    readonly property bool   isResolved    : rowRoot.resolvedGroup > 0
                                             || rowRoot.blockRole === "resolved"

    readonly property string resolvedLabel: {
        switch (model.resolvedMode) {
            case "ours":
                return "Ours accepted"
            case "theirs":
                return "Theirs accepted"
            case "both":
                return "Both accepted"
            default:
                return ""
        }
    }

    readonly property string kind: {
        if (model.type === "blockButton")
            return "cardHeader"

        switch (rowRoot.blockRole) {
            case "marker-start":
                return "oursLabel"
            case "separator":
                return "theirsLabel"
            case "ai-label":
                return "aiLabel"
            case "marker-end":
                return "actionBar"
            default:
                return "codeLine"
        }
    }

    readonly property bool inCard: rowRoot.kind !== "codeLine"
                                   || rowRoot.blockRole === "ours"
                                   || rowRoot.blockRole === "theirs"
                                   || rowRoot.blockRole === "ai"
                                   || rowRoot.blockRole === "resolved"

    readonly property color cardAccent: rowRoot.isResolved ? Style.colors.conflictCardDoneBorder
                                                           : Style.colors.conflictCardOpenBorder

    readonly property color lineTint: {
        switch (rowRoot.blockRole) {
            case "ours":
                return Style.colors.conflictOursBg
            case "theirs":
                return Style.colors.conflictTheirsBg
            case "ai":
                return Style.colors.conflictAiBg
            case "resolved":
                return Style.colors.conflictCardDoneStrip
            default:
                return "transparent"
        }
    }

    /* Signals
     * ****************************************************************************************/
    signal splitRequested(int cursorPos)
    signal mergeUpRequested()
    signal acceptBlockRequested(int blockIndex, string mode)
    signal editBlockRequested(int blockIndex)
    signal askAiRequested(int blockIndex)
    signal useAiRecommendationRequested(int blockIndex)
    signal moveFocusUp()
    signal moveFocusDown()

    /* Object Properties
     * ****************************************************************************************/
    width: parent.width

    height: {
        switch (rowRoot.kind) {
            case "cardHeader":
                return Style.dp(24)
            case "oursLabel":
            case "theirsLabel":
            case "aiLabel":
                return Style.dp(20)
            case "actionBar":
                return Style.dp(34)
            default:
                return Math.max(Style.dp(22), lineEditor.contentHeight + 6)
        }
    }

    onIsCurrentItemChanged: {
        if (rowRoot.isCurrentItem && rowRoot.kind === "codeLine")
            lineEditor.forceActiveFocus()
    }

    /* Children
     * ****************************************************************************************/
    Rectangle {
        id: gutter
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.dp(45)
        color: Style.colors.linePanelBackgroound

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 3
            visible: rowRoot.kind === "codeLine" && model.lineNumber > 0
            text: model.lineNumber > 0 ? model.lineNumber : ""
            color: Style.colors.linePanelForeground
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.captionPt
        }
    }

    Rectangle {
        id: cardEdge
        anchors.left: gutter.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        visible: rowRoot.inCard
        color: rowRoot.cardAccent
    }

    Item {
        id: contentPanel
        anchors.left: rowRoot.inCard ? cardEdge.right : gutter.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        Rectangle {
            anchors.fill: parent
            z: -1
            color: rowRoot.lineTint
        }

        TextArea {
            id: lineEditor
            visible: rowRoot.kind === "codeLine"
            x: -rowRoot.horizontalOffset
            width: 2000

            text: model.text
            readOnly: rowRoot.blockRole === "ai"

            color: Style.colors.editorForeground
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.captionPt
            padding: 0
            leftPadding: 10
            topPadding: 3
            selectionColor: Style.colors.accent
            selectedTextColor: Style.colors.secondaryForeground
            background: null
            selectByMouse: true
            wrapMode: TextArea.NoWrap

            Material.accent: Style.colors.accent

            onTextChanged: {
                if (rowRoot.blockRole === "ai")
                    return
                if (model.text !== text)
                    model.text = text
            }

            Component.onCompleted: rowRoot.textDirectionController?.keepLeftToRight(lineEditor.textDocument)

            Keys.onPressed: (event) => {
                if (rowRoot.blockRole === "ai") {
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true
                    rowRoot.splitRequested(cursorPosition)
                } else if (event.key === Qt.Key_Up) {
                    if (cursorRectangle.y <= topPadding + 2) {
                        event.accepted = true
                        rowRoot.moveFocusUp()
                    }
                } else if (event.key === Qt.Key_Down) {
                    if (cursorRectangle.y + cursorRectangle.height >= height - bottomPadding) {
                        event.accepted = true
                        rowRoot.moveFocusDown()
                    }
                } else if (event.key === Qt.Key_Backspace) {
                    if (cursorPosition === 0) {
                        event.accepted = true
                        rowRoot.mergeUpRequested()
                    }
                }
            }
        }

        Loader {
            id: chromeLoader
            anchors.fill: parent
            active: rowRoot.kind !== "codeLine"

            sourceComponent: {
                switch (rowRoot.kind) {
                    case "cardHeader":
                        return cardHeaderComponent
                    case "oursLabel":
                        return oursLabelComponent
                    case "theirsLabel":
                        return theirsLabelComponent
                    case "aiLabel":
                        return aiLabelComponent
                    case "actionBar":
                        return actionBarComponent
                    default:
                        return null
                }
            }
        }
    }

    /* Components
     * ****************************************************************************************/
    Component {
        id: cardHeaderComponent

        Rectangle {
            color: rowRoot.isResolved ? Style.colors.conflictCardDoneStrip
                                      : Style.colors.conflictCardOpenStrip

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: `CONFLICT #${rowRoot.cardNumber}`
                    color: rowRoot.isResolved ? Style.colors.conflictCardDoneLabel
                                              : Style.colors.conflictCardOpenLabel
                    font.family: Style.fontTypes.jetBrainsMono
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                    font.pixelSize: Style.appFont.microPt
                }

                Text {
                    visible: rowRoot.isResolved
                    text: `${Style.icons.check}  RESOLVED`
                    color: Style.colors.conflictCardDoneLabel
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.microPt
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    visible: rowRoot.isResolved && rowRoot.resolvedLabel !== ""
                    text: rowRoot.resolvedLabel
                    color: Style.colors.conflictCardDoneLabel
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.microPt
                }

                Text {
                    visible: !rowRoot.isResolved
                             && rowRoot.blockIndex === rowRoot.firstOpenBlock
                             && rowRoot.openBlockCount > 0
                    text: rowRoot.openBlockCount === 1 ? "1 conflict left"
                                                       : `${rowRoot.openBlockCount} conflicts left`
                    color: Style.colors.conflictCardOpenLabel
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.microPt
                }
            }
        }
    }

    Component {
        id: oursLabelComponent

        ConflictRegionLabel {
            text: rowRoot.blockLabels[rowRoot.blockIndex]?.ours ?? "OURS"
            labelColor: Style.colors.conflictOursLabel
            tintColor: Style.colors.conflictOursBg
        }
    }

    Component {
        id: theirsLabelComponent

        ConflictRegionLabel {
            text: rowRoot.blockLabels[rowRoot.blockIndex]?.theirs ?? "THEIRS"
            labelColor: Style.colors.conflictTheirsLabel
            tintColor: Style.colors.conflictTheirsBg
        }
    }

    Component {
        id: aiLabelComponent

        ConflictRegionLabel {
            text: `${Style.icons.caretRight} AI`
            labelColor: Style.colors.conflictAiLabel
            tintColor: Style.colors.conflictAiBg
        }
    }

    Component {
        id: actionBarComponent

        Rectangle {
            color: rowRoot.isResolved ? Style.colors.conflictCardDoneStrip
                                      : Style.colors.conflictCardOpenStrip

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 5
                anchors.bottomMargin: 5
                spacing: 8

                ConflictPillButton {
                    text: "Use Ours"
                    leadingText: Style.icons.arrowLeft
                    accentColor: Style.colors.conflictOursLabel
                    tooltip: "Keep the version already on this branch"
                    onClicked: rowRoot.acceptBlockRequested(rowRoot.blockIndex, "ours")
                }

                ConflictPillButton {
                    text: "Use Theirs"
                    trailingText: Style.icons.arrowRight
                    accentColor: Style.colors.conflictTheirsLabel
                    tooltip: "Keep the incoming version"
                    onClicked: rowRoot.acceptBlockRequested(rowRoot.blockIndex, "theirs")
                }

                ConflictPillButton {
                    visible: rowRoot.aiChoiceReveal > 0.01
                    opacity: rowRoot.aiChoiceReveal
                    scale: 0.92 + (0.08 * rowRoot.aiChoiceReveal)
                    transformOrigin: Item.Left
                    text: "Use AI recommendation"
                    leadingText: Style.icons.star
                    accentColor: Style.colors.conflictAssistAccent
                    prominent: true
                    tooltip: "Replace this conflict with the assistant's recommendation"
                    onClicked: rowRoot.useAiRecommendationRequested(rowRoot.blockIndex)
                }

                ConflictPillButton {
                    text: "Both"
                    leadingText: Style.icons.arrowLeft
                    trailingText: Style.icons.arrowRight
                    accentColor: Style.colors.conflictCardDoneBorder
                    tooltip: "Keep both versions, ours first"
                    onClicked: rowRoot.acceptBlockRequested(rowRoot.blockIndex, "both")
                }

                ConflictPillButton {
                    text: "Edit"
                    leadingText: Style.icons.penToSquare
                    accentColor: Style.colors.mutedText
                    tooltip: "Put the caret in this block and resolve it by hand"
                    onClicked: rowRoot.editBlockRequested(rowRoot.blockIndex)
                }

                ConflictPillButton {
                    visible: rowRoot.aiAvailable && !rowRoot.isResolved && !rowRoot.showAiChoice
                    text: rowRoot.assistLabel
                    leadingText: Style.icons.star
                    accentColor: Style.colors.conflictAssistAccent
                    tooltip: "Ask a conflict assistant to suggest a resolution for this chunk"
                    onClicked: rowRoot.askAiRequested(rowRoot.blockIndex)
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
