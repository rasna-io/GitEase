import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreStatusBadge
 * Pill for the status of a file or folder. Every category has its own colour:
 * committed (green), modified (yellow), staged (blue), added (strong blue), deleted (red),
 * renamed (cyan), conflicted (solid red), untracked (violet) and ignored (grey). A folder uses
 * "changed" (yellow) when it holds changed files.
 * ************************************************************************************************/
GitignoreBadge {
    id: root

    property string status: "committed"

    readonly property var look: lookFor(status)

    function makeLook(text, fg, bg, border) {
        return {
            text: text,
            fg: fg,
            bg: bg,
            border: border
        }
    }

    function lookFor(value) {
        switch (value) {
        case "committed":
            return makeLook("Committed",
                            Style.colors.repoItemStatusDoneText,
                            Style.colors.repoItemStatusDoneBg,
                            Style.colors.repoItemStatusDoneText)

        case "modified":
            return makeLook("Modified",
                            Style.colors.onWarningText,
                            Style.colors.modifiediedFile,
                            Style.colors.warning)

        case "changed":
            return makeLook("Changed",
                            Style.colors.onWarningText,
                            Style.colors.modifiediedFile,
                            Style.colors.warning)

        case "staged":
            return makeLook("Staged",
                            Style.colors.repoItemStatusFetchingText,
                            Style.colors.repoItemStatusFetchingBg,
                            Style.colors.repoItemStatusFetchingText)

        case "added":
            return makeLook("Added",
                            Style.colors.onAccentText,
                            Style.colors.accent,
                            Style.colors.accent)

        case "deleted":
            return makeLook("Deleted",
                            Style.colors.onWarningText,
                            Style.colors.deletededFile,
                            Style.colors.error)

        case "renamed":
            return makeLook("Renamed",
                            Style.colors.onWarningText,
                            Style.colors.renamedFile,
                            Style.colors.repoItemStatusPullingText)

        case "conflicted":
            return makeLook("Conflict",
                            Style.colors.onAccentText,
                            Style.colors.error,
                            Style.colors.error)

        case "untracked":
            return makeLook("Untracked",
                            Style.colors.onAccentText,
                            Qt.rgba(0.46, 0.30, 0.86, 1),
                            Qt.rgba(0.46, 0.30, 0.86, 1))

        case "ignored":
            return makeLook("Ignored",
                            Style.colors.mutedText,
                            Style.colors.controlBackground,
                            Style.colors.controlBorder)

        case "folder":
            return makeLook("Folder",
                            Style.colors.secondaryText,
                            Style.colors.controlBackground,
                            Style.colors.controlBorder)

        default:
            return makeLook(value,
                            Style.colors.secondaryText,
                            Style.colors.controlBackground,
                            Style.colors.controlBorder)
        }
    }

    label: look.text
    textColor: look.fg
    fillColor: look.bg
    strong: true
}
