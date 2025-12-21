pragma Singleton
import QtQuick

/*! ***********************************************************************************************
 * Enums
 * Application-wide enumeration definitions for pages, tabs, and other UI states
 * ************************************************************************************************/

QtObject {
    /* Enumerations
     * ****************************************************************************************/
    
    enum WelcomePages {
        WelcomeBanner,
        SetupProfle,
        OpenRepository
    }

    enum RepositorySelectorTab {
        Recents,
        Open,
        Clone
    }
}
