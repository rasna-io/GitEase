import QtQuick

import GitEase

/*! ***********************************************************************************************
 * WelcomeController
 * Manages the welcome flow navigation and state
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    
    // Current page index in the welcome flow
    property int currentPageIndex: Enums.WelcomePages.WelcomeBanner
    
    // Available pages in the welcome flow
    readonly property var pages: [
        "qrc:/GitEase/Qml/Pages/welcomePage.qml",
        "qrc:/GitEase/Qml/Pages/setupProfilePage.qml",
        "qrc:/GitEase/Qml/Pages/openRepositoryPage.qml"
    ]
    
    // Current page URL
    readonly property string currentPage: pages[currentPageIndex]
    
    // Navigation state
    readonly property bool canGoBack: currentPageIndex > Enums.WelcomePages.WelcomeBanner
    readonly property bool canGoNext: currentPageIndex < pages.length - 1
    readonly property bool isFirstPage: currentPageIndex === Enums.WelcomePages.WelcomeBanner
    readonly property bool isLastPage: currentPageIndex === Enums.WelcomePages.OpenRepository
    
    
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
        if (pageIndex >= Enums.WelcomePages.WelcomeBanner && pageIndex <= Enums.WelcomePages.OpenRepository) {
            currentPageIndex = pageIndex
        }
    }
    
    /**
     * Reset to the first page
     */
    function reset() {
        currentPageIndex = Enums.WelcomePages.WelcomeBanner
    }
    
    /**
     * Complete the welcome flow and signal completion
     */
    function completeWelcomeFlow() {
        welcomeFlowCompleted()
    }
}

