import QtQuick

/*! ***********************************************************************************************
 * Page
 * Common base type for every page hosted in MainWindow's SwipeView. Carries the identity
 * (pageId/title/icon) and header/navigation-guard contract every page fulfils.
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string pageId: ""
    property string title: "Page"
    property string icon: ""

    // Header content exposed to MainWindow's Header (see MainWindow.qml)
    property Component headerContent: null

    // Optional navigation guard. If set, called before leaving the page.
    property var onPageChange: null

    // Page-owned transient state (e.g. GraphViewPage's filter cache).
    property var state: ({})
}
