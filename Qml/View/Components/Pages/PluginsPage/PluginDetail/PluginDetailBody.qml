import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailBody
 * Tab content next to the details sidebar. When the selected tab changes, the current content
 * fades out, the new tab is swapped in, and it fades in while rising slightly.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    plugin: null
    property bool   wide: true
    property real   pageWidth: 0
    property color  categoryColor: Style.colors.accent
    property string currentTab: "overview"

    property string aboutText: ""
    property var    screenshots: []
    property var    features: []
    property var    changelog: []
    property var    tags: []
    property var    detailRows: []

    //! Tab that is actually on screen; trails currentTab by the fade-out time
    property string shownTab: "overview"

    /* Signals
     * ****************************************************************************************/
    signal tabRequested(string tabId)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: bodyGrid.implicitHeight + Style.dp(48)

    onCurrentTabChanged: {
        tabSwitch.restart()
    }

    /* Children
     * ****************************************************************************************/
    SequentialAnimation {
        id: tabSwitch

        NumberAnimation {
            target: mainColumn
            property: "opacity"
            to: 0
            duration: 80
            easing.type: Easing.OutQuad
        }

        ScriptAction {
            script: {
                root.shownTab = root.currentTab
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: mainColumn
                property: "opacity"
                to: 1
                duration: 200
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: tabShift
                property: "y"
                from: Style.dp(8)
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }
    GridLayout {
        id: bodyGrid
        width: root.pageWidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Style.dp(24)
        columns: root.wide ? 2 : 1
        columnSpacing: Style.dp(24)
        rowSpacing: Style.dp(16)

        // Main column
        ColumnLayout {
            id: mainColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Style.dp(16)

            transform: Translate {
                id: tabShift
            }

            PluginDetailOverview {
                visible: root.shownTab === "overview"
                pluginId: root.plugin?.pluginId ?? ""
                screenshots: root.screenshots
                aboutText: root.aboutText
                installGuide: root.plugin?.installGuide || ""
                features: root.features
                tint: root.categoryColor

                onSeeAllFeaturesRequested: root.tabRequested("features")
            }

            PluginDetailFeatureGrid {
                visible: root.shownTab === "features"
                features: root.features
                tint: root.categoryColor
            }

            PluginDetailChangelog {
                visible: root.shownTab === "changelog"
                changelog: root.changelog
                tint: root.categoryColor
            }
        }

        PluginDetailSidebar {
            Layout.fillWidth: !root.wide
            Layout.preferredWidth: root.wide ? Style.dp(300) : -1
            Layout.maximumWidth: root.wide ? Style.dp(300) : -1
            Layout.alignment: Qt.AlignTop

            plugin: root.plugin
            detailRows: root.detailRows
            tags: root.tags
            tint: root.categoryColor
        }
    }
}
