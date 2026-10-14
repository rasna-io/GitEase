import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * FileFilterBar
 * Search field, "Hidden files" switch and the status filter chips of the Files view.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string search:     ""
    property bool   showHidden: false
    //! "all", "changes", "untracked", "ignored", "committed" or "trackedIgnored".
    property string filter:     "all"
    property var    stats:      ({ all: 0, changes: 0, untracked: 0, ignored: 0, committed: 0, trackedIgnored: 0 })

    /* Signals
     * ****************************************************************************************/
    signal searchEdited(string text)
    signal showHiddenToggled(bool value)
    signal filterSelected(string key)

    /* Object Properties
     * ****************************************************************************************/
    spacing: Style.dp(10)

    /* Children
     * ****************************************************************************************/
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.dp(12)

        GitignoreSearchField {
            Layout.fillWidth: true
            placeholderText: "Search files"
            text: root.search
            onTextEdited: root.searchEdited(text)
        }

        GitignoreCheckBox {
            text: "Hidden files"
            checked: root.showHidden
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
            onToggled: root.showHiddenToggled(checked)

            GitignoreToolTip {
                visible: parent.hovered
                text: "Show files and folders whose name starts with a dot"
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Style.dp(6)

        FileFilterChip {
            key: "all"
            label: "All"
            count: root.stats.all
            active: root.filter === key
            onClicked: root.filterSelected(key)
        }

        FileFilterChip {
            key: "changes"
            label: "Changed"
            count: root.stats.changes
            active: root.filter === key
            onClicked: root.filterSelected(key)
        }

        FileFilterChip {
            key: "untracked"
            label: "Untracked"
            count: root.stats.untracked
            active: root.filter === key
            onClicked: root.filterSelected(key)
        }

        FileFilterChip {
            key: "ignored"
            label: "Ignored"
            count: root.stats.ignored
            active: root.filter === key
            onClicked: root.filterSelected(key)
        }

        FileFilterChip {
            key: "committed"
            label: "Committed"
            count: root.stats.committed
            active: root.filter === key
            onClicked: root.filterSelected(key)
        }

        FileFilterChip {
            visible: root.stats.trackedIgnored > 0 || root.filter === "trackedIgnored"
            key: "trackedIgnored"
            label: "Tracked & ignored"
            count: root.stats.trackedIgnored
            active: root.filter === key
            onClicked: root.filterSelected(key)
        }
    }
}
