import QtQuick

/*! ***********************************************************************************************
 * WelcomeController
 * Manages the welcome flow navigation and state
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    
    // Current page index in the welcome flow
    property int currentPageIndex: 0
    
    // Available pages in the welcome flow
    readonly property var pages: [
        "qrc:/GitEase/Qml/Pages/welcomePage.qml",
        "qrc:/GitEase/Qml/Pages/setupProfilePage.qml",
        "qrc:/GitEase/Qml/Pages/openRepositoryPage.qml"
    ]
    
    // Current page URL
    readonly property string currentPage: pages[currentPageIndex]
    
    // Navigation state
    readonly property bool canGoBack: currentPageIndex > 0
    readonly property bool canGoNext: currentPageIndex < pages.length - 1
    readonly property bool isFirstPage: currentPageIndex === 0
    readonly property bool isLastPage: currentPageIndex === pages.length - 1
    
    
    /* Signals
     * ****************************************************************************************/
    
    signal welcomeFlowCompleted()
    
    
    /* Functions
     * ****************************************************************************************/
    
    /**
     * Navigate to the next page
     */
    function nextPage() {
        if (canGoNext) {
            currentPageIndex++
        } else if (isLastPage) {
            completeWelcomeFlow()
        }
    }
    
    /**
     * Navigate to the previous page
     */
    function previousPage() {
        if (canGoBack) {
            currentPageIndex--
        }
    }
    
    /**
     * Navigate to a specific page by index
     */
    function goToPage(pageIndex) {
        if (pageIndex >= 0 && pageIndex < pages.length) {
            currentPageIndex = pageIndex
        }
    }
    
    /**
     * Reset to the first page
     */
    function reset() {
        currentPageIndex = 0
    }
    
    /**
     * Complete the welcome flow and signal completion
     */
    function completeWelcomeFlow() {
        welcomeFlowCompleted()
    }
}

