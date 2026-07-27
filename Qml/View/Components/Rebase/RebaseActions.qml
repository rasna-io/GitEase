pragma Singleton

import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * RebaseActions
 * ************************************************************************************************/
QtObject {
    id: root

    readonly property string pick:   "pick"
    readonly property string reword: "reword"
    readonly property string squash: "squash"
    readonly property string fixup:  "fixup"
    readonly property string edit:   "edit"
    readonly property string drop:   "drop"

    readonly property var all: [root.pick, root.reword, root.squash,
                                root.fixup, root.edit, root.drop]

    // todo
    readonly property var supported: [root.pick, root.drop]

    function colorOf(action) {
        switch (action) {
            case root.reword:
                return Style.colors.rebaseActionReword
            case root.squash:
                return Style.colors.rebaseActionSquash
            case root.fixup:
                return Style.colors.rebaseActionFixup
            case root.edit:
                return Style.colors.rebaseActionEdit
            case root.drop:
                return Style.colors.rebaseActionDrop
            default:
                return Style.colors.rebaseActionPick
        }
    }

    function descriptionOf(action) {
        switch (action) {
            case root.reword:
                return "Edit message"
            case root.squash:
                return "Meld into previous"
            case root.fixup:
                return "Like squash, discard message"
            case root.edit:
                return "Stop to amend"
            case root.drop:
                return "Remove this commit"
            default:
                return "Use commit as-is"
        }
    }

    function shortcutFor(action) {
        switch (action) {
            case root.reword:
                return "R"
            case root.squash:
                return "S"
            case root.fixup:
                return "F"
            case root.edit:
                return "E"
            case root.drop:
                return "D"
            default:
                return "P"
        }
    }

    function fromShortcut(key) {
        switch (key) {
            case "R":
                return root.reword
            case "S":
                return root.squash
            case "F":
                return root.fixup
            case "E":
                return root.edit
            case "D":
                return root.drop
            case "P":
                return root.pick
            default:
                return ""
        }
    }

    function startsGroup(action) {
        return action === root.drop
    }

    function isSupported(action) {
        return root.supported.indexOf(action) !== -1
    }

    function operationFor(action) {
        // TODO
        return action === root.drop ? "skip" : "pick"
    }
}
