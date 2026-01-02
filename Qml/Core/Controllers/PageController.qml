import QtQuick

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * PageController
 * Manages the creation, navigation, and lifecycle of pages within the application.
 * Each page represents a workspace view with its own dock configuration and repository context.
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property AppModel appModel

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/

    Component.onCompleted: {
        if (!root.appModel?.pages || root.appModel?.pages.length === 0) {
            root.createPage(
                        "graph",
                        "Graph View",
                        "qrc:/GitEase/Qml/Pages/GraphViewPage.qml",
                        Style.icons.workflow)

            // root.createPage(
            //             "blank",
            //             "Blank Page",
            //             "qrc:/GitEase/Qml/Pages/BlankPage.qml",
            //             Style.icons.lightbulb)
        } else if (!root.appModel?.currentPage && root.appModel?.pages?.length) {
            root.appModel.currentPage = appModel.pages[0]
        }
    }

    /* Functions
     * ****************************************************************************************/
    function _findPage(pageId) {
        return (root.appModel?.pages || []).find(p => p && p.id === pageId) || null
    }

    /**
     * Create a new page instance
     *
     * @param pageId unique id (if omitted, one will be generated)
     * @param title display title
     * @param source QML source url (qrc:/...)
     * @param icon optional icon glyph (FontAwesome codepoint)
     */
    function createPage(pageId, title, source, icon) {
        const id = (pageId && pageId.length) ? pageId : ("page_" + Date.now())

        // If already exists, just switch to it
        const existing = _findPage(id)
        if (existing) {
            root.appModel.currentPage = existing
            return existing
        }

        var pageComponent = Qt.createComponent("qrc:/GitEase/Qml/Core/Models/Page.qml")
        if (pageComponent.status !== Component.Ready) {
            console.error("[PageController] Failed to create Page component:", pageComponent.errorString())
            return null
        }

        var page = pageComponent.createObject(root, {
            id: id,
            title: title || "Page",
            source: source || "",
            icon: icon || ""
        })

        root.appModel?.pages?.push(page)

        root.appModel.currentPage = page
        return page
    }

    /**
     * Switch the active page to the specified page
     */
    function switchToPage(pageId) {
        const page = _findPage(pageId)
        if (!page)
            return

        root.appModel.currentPage = page
    }
}
