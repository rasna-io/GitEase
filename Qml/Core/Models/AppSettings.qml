pragma Singleton

import QtQuick

/*! ***********************************************************************************************
 * AppSettings
 * Simple flag holder for application state
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    
    // Flag to determine if the welcome flow has been completed
    // If true, show main application window
    // If false, show welcome page flow
    // You can manually set this flag as needed
    property bool hasCompletedWelcome: false
}

