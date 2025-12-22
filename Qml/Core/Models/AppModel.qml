import QtQuick

import GitEase

/*! ***********************************************************************************************
 * AppModel
 * Main application data model managing repositories, current repository state, and recent repositories list
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var repositories: []
    property var currentRepository: null
    property var recentRepositories: []


    /* Signals
     * ****************************************************************************************/


    /* Functions
     * ****************************************************************************************/
    
    /**
     * Save application state to persistent storage
     */
    function save() {

    }

    /**
     * Load application state from persistent storage
     */
    function load() {

    }

    /**
     * Set default values for application state
     */
    function setDefaults() {

    }


    Component.onCompleted: load()

}
