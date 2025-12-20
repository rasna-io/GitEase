/*! ***********************************************************************************************
 * GitService : QML wrapper for GitWrapperCPP to expose Git operations to QML components.
 *              Follows the UML design as QML_Service.
 * ************************************************************************************************/
pragma Singleton
import QtQuick

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property GitWrapperCPP gitWrapper: GitWrapperCPP {
        id: gitWrapper
    }

    property bool isRepositoryOpen: gitWrapper.isOpen

    property string currentRepoPath: gitWrapper.currentRepoPath


    /* Signals
     * ****************************************************************************************/

    /* Functions
     * ****************************************************************************************/

    function initRepository(path) {
        var result = gitWrapper.init(path);
        return result;
    }

    /**
     * \brief Open an existing Git repository
     * \param path Path to repository
     * \return QVariantMap with {"success": bool, "data": path, "error": message}
     */
    function openRepository(path) {
        var result = gitWrapper.open(path);
        return result;
    }

    /**
     * \brief Clone a remote repository
     * \param url Remote repository URL
     * \param localPath Local path where to clone
     * \return QVariantMap with {"success": bool, "data": localPath, "error": message}
     */
    function cloneRepository(url, localPath) {
        var result = gitWrapper.clone(url, localPath);
        return result;
    }

    /**
     * \brief Close the current repository
     * \return QVariantMap with {"success": bool, "error": message}
     */
    function closeRepository() {
        var result = gitWrapper.close();
        return result;
    }

    /**
     * \brief Get repository status
     * \param repoPath Path to repository (optional, uses current if empty)
     * \return QVariantMap with status information
     */
    function getStatus(repoPath) {
        var result = gitWrapper.status(repoPath || "");
        return result;
    }

    /**
     * \brief Get commit history
     * \param repoPath Path to repository (optional, uses current if empty)
     * \param limit Maximum number of commits to return (default: 50)
     * \return QVariantList of commit objects
     */
    function getCommits(repoPath, limit) {
        var result = gitWrapper.getCommits(repoPath || "", limit || 50);
        return result;
    }

    /**
     * \brief Get list of branches
     * \param repoPath Path to repository (optional, uses current if empty)
     * \return QVariantList of branch objects
     */
    function getBranches(repoPath) {
        var result = gitWrapper.getBranches(repoPath || "");
        return result;
    }
}
