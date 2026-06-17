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
    property var pluginsData: []
    readonly property int minCardWidth: 400
    readonly property int minCardHeight: 270

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
