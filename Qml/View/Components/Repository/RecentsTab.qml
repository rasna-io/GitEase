import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RecentsTab
 * Search + list of recent repositories. Exposes the chosen path via `selectedPath` and emits
 * `accepted()` on double-click.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController repositoryController: null
    property var    recentRepositories: []
    property string selectedPath: ""
    property string search: ""

    readonly property var filtered: {
        var q = root.search.toLowerCase()
        var list = root.recentRepositories || []
        if (q === "")
            return list
        return list.filter(function(r) {
            return r && (((r.name || "").toLowerCase().indexOf(q) >= 0)
                         || ((r.path || "").toLowerCase().indexOf(q) >= 0))
        })
    }

    /* Signals
     * ****************************************************************************************/
    signal accepted()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 320

    /* Functions
     * ****************************************************************************************/
    function reset() {
        root.selectedPath = ""
        root.search = ""
        searchField.text = ""
    }

    function colorOf(m) {
        var ctrl = root.repositoryController
        if (!ctrl)
            return (m && m.color) ? m.color : "#B9FAB9"
        return ctrl.isValidRepoColor(m ? m.color : "")
                ? m.color
                : ctrl.repoColor(m ? m.path : "")
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RepoTextField {
            id: searchField
            placeholderText: "Search recent repos..."
            icon: Style.icons.search
            onTextChanged: root.search = text
        }

        ScrollView {
            id: recentsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: recentsScroll.availableWidth
                spacing: 6

                Text {
                    visible: root.filtered.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    text: "No recent repositories"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 12
                    color: Style.colors.mutedText
                }

                Repeater {
                    model: root.filtered

                    RecentRepositoryRow {
                        Layout.fillWidth: true
                        repoName: modelData?.name ?? ""
                        repoPath: modelData?.path ?? ""
                        avatarColor: root.colorOf(modelData)
                        selected: root.selectedPath !== "" && root.selectedPath === (modelData?.path ?? "")

                        onClicked: root.selectedPath = modelData?.path ?? ""
                        onDoubleClicked: {
                            root.selectedPath = modelData?.path ?? ""
                            root.accepted()
                        }
                    }
                }
            }
        }
    }
}
