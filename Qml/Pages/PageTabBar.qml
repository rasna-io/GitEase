import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*! ***********************************************************************************************
 * PageTabBar
 * Vertical sidebar component for page and repository navigation.
 * Displays list of open pages and available repositories.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var pages: []
    property var currentPage: null
    property var repositories: []
    property var currentRepository: null

    /* Signals
     * ****************************************************************************************/
    signal pageClicked(string pageId)
    // signal repositorySelected(string repositoryId)
    // signal openRepositoryRequested()

    /* Object Properties
     * ****************************************************************************************/
    // width: 230
    // color: "#2b2b2b"
    // radius: 0

    /* Children
     * ****************************************************************************************/
    // Pages area (top section)
    // TODO: Implement pages list with:
    // - Flickable/ListView for pages
    // - Page items with title, icon
    // - Active page highlighting

    // Repositories area (bottom section)
    // TODO: Implement repositories list with:
    // - ListView for repositories
    // - Repository items with name, icon
    // - Add/open repository button
    // - Current repository highlighting
}


