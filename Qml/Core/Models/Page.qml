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

    // Plugin pages set this to true so the rail can draw a separator before the first one.
    property bool isPlugin: false
    // Badge count shown in the rail item. -1 hides the badge.
    property int  badgeCount: -1
    // Override badge background color (defaults to accent blue)
    property color badgeColor: "#3B82F6"
}
