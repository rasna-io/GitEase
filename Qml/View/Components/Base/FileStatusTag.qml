import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * FileStatusTag
 * Reusable change-status tag for a file.
 * - compact  : single colored letter (M / A / D / R / U), no background
 * - expanded : full word ("Modified", ...) on a colored rounded background
 *
 * Feed it one of the two GitFileStatus enum families:
 * - deltaStatus (GitFileStatus.ADDED / DELETED / MODIFIED / RENAMED / UNTRACKED)
 * - fileStatus  (GitFileStatus.Modified / StagedNew / Untracked / ...)
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool compact      : false
    property int  deltaStatus  : -1
    property int  fileStatus   : -1

    readonly property string statusKind: {
        if (root.deltaStatus >= 0) {
            switch (root.deltaStatus) {
            case GitFileStatus.ADDED:       return "added"
            case GitFileStatus.DELETED:     return "deleted"
            case GitFileStatus.MODIFIED:    return "modified"
            case GitFileStatus.RENAMED:     return "renamed"
            case GitFileStatus.UNTRACKED:   return "untracked"
            }
            return ""
        }

        switch (root.fileStatus) {
        case GitFileStatus.StagedNew:       return "added"
        case GitFileStatus.Deleted:
        case GitFileStatus.StagedDeleted:   return "deleted"
        case GitFileStatus.Modified:
        case GitFileStatus.TypeChange:
        case GitFileStatus.StagedModified:  return "modified"
        case GitFileStatus.Renamed:
        case GitFileStatus.StagedRenamed:   return "renamed"
        case GitFileStatus.Untracked:       return "untracked"
        }
        return ""
    }

    readonly property string statusLetter: {
        switch (root.statusKind) {
        case "added":       return "A"
        case "deleted":     return "D"
        case "modified":    return "M"
        case "renamed":     return "R"
        case "untracked":   return "U"
        }
        return ""
    }

    readonly property string statusText: {
        switch (root.statusKind) {
        case "added":       return "Added"
        case "deleted":     return "Deleted"
        case "modified":    return "Modified"
        case "renamed":     return "Renamed"
        case "untracked":   return "Untracked"
        }
        return ""
    }

    readonly property color statusColor: {
        switch (root.statusKind) {
        case "added":       return Style.colors.addedFile
        case "deleted":     return Style.colors.deletededFile
        case "modified":    return Style.colors.modifiediedFile
        case "renamed":     return Style.colors.renamedFile
        case "untracked":   return Style.colors.untrackedFile
        }
        return "transparent"
    }

    /* Object Properties
     * ****************************************************************************************/
    visible: statusKind !== ""
    radius: 3
    color: root.compact ? "transparent" : root.statusColor

    implicitWidth: tagLabel.implicitWidth + (root.compact ? 0 : 14)
    implicitHeight: tagLabel.implicitHeight + (root.compact ? 0 : 4)

    /* Children
     * ****************************************************************************************/
    Label {
        id: tagLabel
        anchors.centerIn: parent
        text: root.compact ? root.statusLetter : root.statusText
        color: root.compact ? Qt.darker(root.statusColor, 1.5) : Style.colors.titleText
        font.family: Style.fontTypes.roboto
        font.pixelSize: root.compact ? Style.appFont.defaultPt : Style.appFont.mediumPt
        font.bold: root.compact
    }
}
