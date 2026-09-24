import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

Rectangle {
    id: root

    property var  chunkData: []
    property var  diffData:  []
    property bool chunkMode: true
    property bool readOnly:  true

    color:  "#1E1E1E"
    clip:   true

    // ── JS syntax colorizer (produces HTML) ──────────────────────────────────
    QtObject {
        id: hl

        readonly property string clrKeyword: "#569CD6"
        readonly property string clrType:    "#4EC9B0"
        readonly property string clrProp:    "#9CDCFE"
        readonly property string clrString:  "#CE9178"
        readonly property string clrNumber:  "#B5CEA8"
        readonly property string clrComment: "#6A9955"
        readonly property string clrSignal:  "#C586C0"
        readonly property string clrBuiltin: "#DCDCAA"

        readonly property var keywords: [
            "import","property","signal","function","var","let","const",
            "if","else","for","while","do","break","continue","return",
            "switch","case","default","try","catch","finally","throw",
            "new","delete","typeof","instanceof","in","of",
            "true","false","null","undefined","this",
            "readonly","required","pragma","as","alias"
        ]
        readonly property var builtins: [
            "console","Math","JSON","Date","Qt","Object","Array",
            "parseInt","parseFloat","isNaN"
        ]

        function escapeHtml(t) {
            return t.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")
        }

        function span(color, text) {
            return '<font color="' + color + '">' + text + '</font>'
        }

        // Tokenize a single line into colored HTML
        function colorize(raw) {
            if (!raw || raw.length === 0) return ""

            // single-line comment: everything from // onward
            var commentIdx = -1
            var inStr = false, strChar = ""
            for (var ci = 0; ci < raw.length; ci++) {
                var ch = raw[ci]
                if (inStr) {
                    if (ch === "\\" ) { ci++; continue }
                    if (ch === strChar) inStr = false
                } else {
                    if (ch === '"' || ch === "'" || ch === "`") { inStr = true; strChar = ch }
                    else if (ch === "/" && raw[ci+1] === "/") { commentIdx = ci; break }
                }
            }

            var codePart    = commentIdx >= 0 ? raw.substring(0, commentIdx) : raw
            var commentPart = commentIdx >= 0 ? raw.substring(commentIdx)    : ""

            // Tokenize codePart character by character
            var out = ""
            var i   = 0
            while (i < codePart.length) {
                var c = codePart[i]

                // String literal
                if (c === '"' || c === "'" || c === "`") {
                    var q = c, s = c, j = i + 1
                    while (j < codePart.length) {
                        var sc = codePart[j]
                        s += sc
                        if (sc === "\\") { j++; if (j < codePart.length) { s += codePart[j]; j++ }; continue }
                        if (sc === q) { j++; break }
                        j++
                    }
                    out += span(clrString, escapeHtml(s))
                    i = j
                    continue
                }

                // Identifier or keyword
                if (/[a-zA-Z_$]/.test(c)) {
                    var word = ""
                    var k = i
                    while (k < codePart.length && /[a-zA-Z0-9_$.]/.test(codePart[k]))
                        word += codePart[k++]

                    // strip trailing dots for type check (e.g. "anchors.fill")
                    var base = word.split(".")[0]

                    if (keywords.indexOf(base) >= 0) {
                        out += '<b>' + span(clrKeyword, escapeHtml(word)) + '</b>'
                    } else if (builtins.indexOf(base) >= 0) {
                        out += span(clrBuiltin, escapeHtml(word))
                    } else if (/^on[A-Z]/.test(word)) {
                        out += span(clrSignal, escapeHtml(word))
                    } else if (/^[A-Z]/.test(word)) {
                        out += span(clrType, escapeHtml(word))
                    } else if (k < codePart.length && /\s*:/.test(codePart.substring(k, k+3))) {
                        out += span(clrProp, escapeHtml(word))
                    } else {
                        out += escapeHtml(word)
                    }
                    i = k
                    continue
                }

                // Number
                if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(codePart[i+1] || ""))) {
                    var num = ""
                    var n = i
                    while (n < codePart.length && /[0-9a-fA-FxX.]/.test(codePart[n]))
                        num += codePart[n++]
                    out += span(clrNumber, escapeHtml(num))
                    i = n
                    continue
                }

                out += escapeHtml(c)
                i++
            }

            if (commentPart)
                out += '<i>' + span(clrComment, escapeHtml(commentPart)) + '</i>'

            return out
        }
    }

    // ── Flatten chunk/diff data into a display model ─────────────────────────
    ListModel { id: lineModel }

    function rebuild() {
        lineModel.clear()
        var rows = chunkMode ? chunkData : diffData
        if (!rows || rows.length === 0) return

        for (var i = 0; i < rows.length; i++) {
            var r = rows[i]

            if (chunkMode) {
                // rowType: "hidden" | "diff" | "context"
                if (r.rowType === "hidden") {
                    lineModel.append({
                        kind:      "hidden",
                        leftNum:   "",
                        rightNum:  "",
                        indicator: "…",
                        rawText:   "  ··· " + (r.hiddenCount || "") + " unchanged lines ···",
                        htmlText:  ""
                    })
                } else {
                    var dt = r.diffType
                    // Added=1 with empty left → green; Deleted=2 with empty right → red; else context
                    var kind = "context"
                    if (dt === 1)      kind = "added"
                    else if (dt === 2) kind = "deleted"
                    else if (dt === 3) kind = (r.leftText ? "deleted" : "added")

                    var text = kind === "deleted" ? (r.leftText || "") : (r.rightText || r.leftText || "")
                    lineModel.append({
                        kind:      kind,
                        leftNum:   r.oldLineNum > 0 ? r.oldLineNum : "",
                        rightNum:  r.newLineNum > 0 ? r.newLineNum : "",
                        indicator: kind === "added" ? "+" : kind === "deleted" ? "-" : " ",
                        rawText:   text,
                        htmlText:  hl.colorize(text)
                    })

                    // Modified row has both sides — add deleted then added
                    if (dt === 3 && r.leftText && r.rightText) {
                        lineModel.append({
                            kind:      "added",
                            leftNum:   "",
                            rightNum:  r.newLineNum > 0 ? r.newLineNum : "",
                            indicator: "+",
                            rawText:   r.rightText,
                            htmlText:  hl.colorize(r.rightText)
                        })
                    }
                }
            } else {
                var dt2  = r.type !== undefined ? r.type : 0
                var kind2 = dt2 === 1 ? "added" : dt2 === 2 ? "deleted" : "context"
                var text2 = r.rightText || r.content || ""
                lineModel.append({
                    kind:      kind2,
                    leftNum:   r.oldLine > 0 ? r.oldLine : "",
                    rightNum:  r.newLine > 0 ? r.newLine : "",
                    indicator: kind2 === "added" ? "+" : kind2 === "deleted" ? "-" : " ",
                    rawText:   text2,
                    htmlText:  hl.colorize(text2)
                })
            }
        }
    }

    onChunkDataChanged: rebuild()
    onDiffDataChanged:  rebuild()
    onChunkModeChanged: rebuild()
    Component.onCompleted: rebuild()

    // ── View ─────────────────────────────────────────────────────────────────
    ListView {
        id: listView
        anchors.fill: parent
        model:        lineModel
        clip:         true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical:   ScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            width:  Math.max(listView.width, lineText.implicitWidth + 84)
            height: 20

            color: model.kind === "added"   ? "#1a3a1a" :
                   model.kind === "deleted" ? "#3a1a1a" :
                   model.kind === "hidden"  ? "#2a2a40" : "transparent"

            // Left line number
            Text {
                id: leftNum
                width: 36
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:  model.leftNum
                color: "#606060"
                font { family: Style.fontTypes.jetBrainsMono; pixelSize: 12 }
                horizontalAlignment: Text.AlignRight
                rightPadding: 4
            }

            // +/- indicator
            Text {
                id: indicator
                width: 12
                anchors { left: leftNum.right; verticalCenter: parent.verticalCenter }
                text:  model.indicator
                color: model.kind === "added"   ? "#4EC9B0" :
                       model.kind === "deleted" ? "#F14C4C" : "#606060"
                font { family: Style.fontTypes.jetBrainsMono; pixelSize: 12 }
                horizontalAlignment: Text.AlignHCenter
            }

            // Right line number
            Text {
                id: rightNum
                width: 36
                anchors { left: indicator.right; verticalCenter: parent.verticalCenter }
                text:  model.rightNum
                color: "#606060"
                font { family: Style.fontTypes.jetBrainsMono; pixelSize: 12 }
                rightPadding: 6
            }

            // Code text
            Text {
                id: lineText
                anchors { left: rightNum.right; verticalCenter: parent.verticalCenter; right: parent.right }
                text:       model.htmlText !== "" ? model.htmlText : model.rawText
                textFormat: model.htmlText !== "" ? Text.RichText  : Text.PlainText
                color:      model.kind === "hidden" ? "#858585" : "#D4D4D4"
                font { family: Style.fontTypes.jetBrainsMono; pixelSize: 12 }
                elide:      Text.ElideRight
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: lineModel.count === 0
            text:    "No changes"
            color:   "#555555"
            font { family: Style.fontTypes.jetBrainsMono; pixelSize: 13 }
        }
    }
}
