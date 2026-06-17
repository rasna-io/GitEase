import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * PluginsPage
 * Responsive plugins page showing list of plugins
 */

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var pluginsData: [
        {
            id: "markdown.viewer",
            name: "Markdown Viewer",
            description: "Renders Markdown files inside diff and preview panels.",
            latestVersion: "1.2.0",
            minAppVersion: "1.0.0",
            size: "1.8 MB",
            author: "GitEase Team",
            enabled: true,
            type: "diff",
            releaseDate: "2024-03-10",
            iconUrl: "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/markdown/markdown-original.svg"
        },
        {
            id: "ai.assistant",
            name: "AI Assistant",
            description: "Generates commit messages and summarizes diffs.",
            latestVersion: "0.9.3",
            minAppVersion: "1.1.0",
            size: "4.6 MB",
            author: "GitEase Labs",
            enabled: false,
            type: "service",
            releaseDate: "2024-06-21",
            iconUrl: "https://cdn-icons-png.flaticon.com/512/4712/4712027.png"
        },
        {
            id: "git.stats",
            name: "Git Stats",
            description: "Shows repository statistics and contributor insights.",
            latestVersion: "1.0.5",
            minAppVersion: "1.0.0",
            size: "2.3 MB",
            author: "Community",
            enabled: true,
            type: "dock",
            releaseDate: "2023-11-05",
            iconUrl: "https://cdn-icons-png.flaticon.com/512/2111/2111288.png"
        },
        {
            id: "auth.github",
            name: "GitHub Auth",
            description: "Handles authentication with GitHub accounts.",
            latestVersion: "2.1.0",
            minAppVersion: "1.2.0",
            size: "3.1 MB",
            author: "GitEase Team",
            enabled: true,
            type: "auth",
            releaseDate: "2024-01-18",
            iconUrl: "https://cdn-icons-png.flaticon.com/512/733/733553.png"
        },
        {
            id: "cpp.diff",
            name: "C++ Diff Highlighter",
            description: "Advanced diff view for C++ files.",
            latestVersion: "1.3.2",
            minAppVersion: "1.1.0",
            size: "5.4 MB",
            author: "Syntax Labs",
            enabled: false,
            type: "diff",
            releaseDate: "2024-08-30",
            iconUrl: "https://cdn-icons-png.flaticon.com/512/6132/6132222.png"
        },
        {
            id: "terminal.plugin",
            name: "Terminal Plugin",
            description: "Embedded terminal inside GitEase.",
            latestVersion: "0.8.0",
            minAppVersion: "1.0.0",
            size: "2.9 MB",
            author: "DevTools Inc",
            enabled: true,
            type: "service",
            releaseDate: "2023-09-14",
            iconUrl: "https://cdn-icons-png.flaticon.com/512/25/25694.png"
        }
    ]
    readonly property int minCardWidth: 400
    readonly property int minCardHeight: 270

    // Header exposed to MainWindow
    property Component headerContent: Component {
        PluginsPageHeader {
            id: pluginsPageHeader
        }
    }

    onPluginsDataChanged: {
        pluginsModel.clear()

        for(var i = 0; i < root.pluginsData.length; i++) {
            var plugin = root.pluginsData[i];
            pluginsModel.append({
                         "pluginId": plugin.id,
                         "name": plugin.name,
                         "description": plugin.description,
                         "author": plugin.author,
                         "latestVersion": plugin.latestVersion,
                         "minAppVersion": plugin.minAppVersion,
                         "size": plugin.size,
                         "iconUrl": plugin.iconUrl,
                         "releaseDate": plugin.releaseDate
                     })
        }
    }

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    ListModel {
        id: pluginsModel
    }

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        model: pluginsModel

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        // Check how many columns fit inside the current width of the page
        property int columns: Math.max(1, Math.floor(width / root.minCardWidth))

        cellWidth: width / columns
        cellHeight: root.minCardHeight

        delegate: Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            PluginCard {
                anchors.centerIn: parent
                width: gridView.cellWidth - 20
                height: gridView.cellHeight - 20
                pluginId: model.pluginId || ""
                name: model.name || ""
                description: model.description || ""
                author: model.author || ""
                latestVersion: model.latestVersion || ""
                minAppVersion: model.minAppVersion || ""
                size: model.size || ""
                iconUrl: model.iconUrl || ""
                releaseDate: model.releaseDate || ""
            }
        }
    }
}
