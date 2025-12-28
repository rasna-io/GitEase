import QtQuick

import GitEase

/*! ***********************************************************************************************
 * RepositoryController
 * Manages repository operations including opening, cloning, and selecting repositories.
 * Handles repository lifecycle and maintains recent repositories list.
 * ************************************************************************************************/
Item {
    id : root

    /* Property Declarations
     * ****************************************************************************************/
    required property AppModel appModel
    property int maxRecentLength: 10

    /* Signals
     * ****************************************************************************************/
    signal repositorySelected(Repository repo)

    /* Functions
     * ****************************************************************************************/
    
    /**
     * Open an existing repository at the specified path
     */
    function openRepository(path :string) : bool {
        var result = GitService.open(path)

        if(result.success){
            createRepositoryComponent(path)
        }

        return result.success
    }

    /**
     * Clone a repository from URL to the specified local path
     */
    function cloneRepository(path, url) : bool {
        let repoName = extractRepoName(url)

        var result = GitService.clone(url, path + "/" + repoName)

        if(result.success){
            createRepositoryComponent(path, repoName)
        }

        return result
    }

    /**
     * Create and initialize a Repository component for the given path
     */
    function createRepositoryComponent(path, name = "") {
        // Check if already exists
        var repo = appModel.repositories.find(r => r.path === path)
        if (!repo){
            // Create new repository
            var repoComponent = Qt.createComponent("qrc:/GitEase/Qml/Core/Models/Repository.qml")
            if (repoComponent.status === Component.Ready) {

                if (name === "")
                    name = path.split('/').pop() || path.split('\\').pop() || "Repository"

                repo = repoComponent.createObject(root, {
                    id: "repo_" + Date.now(),
                    path: path,
                    name: name
                })
                appModel.repositories.push(repo)
            }
        }

        selectRepository(repo.id)
    }

    /**
     * Select a repository by ID and update current repository state
     */
    function selectRepository(repoId) {
        var repo = appModel.repositories.find(r => r.id === repoId)
        if (repo) {
            appModel.currentRepository = repo
            root.repositorySelected(repo)

            // Add to recent
            if (!appModel.recentRepositories.includes(repo)) {
                appModel.recentRepositories.unshift(repo)
                if (appModel.recentRepositories.length > root.maxRecentLength) {
                    appModel.recentRepositories.pop()
                }
                // Reassign to trigger change notifications for bindings
                appModel.recentRepositories = appModel.recentRepositories.slice()
                appModel.save()
            }
        }
    }

    /**
     * Extracts the repository name from a Git repository URL.
     *
     * Supported formats:
     *  - HTTPS: https://github.com/owner/repository.git
     *  - SSH:   git@github.com:owner/repository.git
     *
     * Behavior:
     *  - Returns only the repository name (last path segment)
     *
     */
    function extractRepoName(repoUrl : string) : string {
        // remove trailing .git
        let url = repoUrl.replace(/\.git$/, "");

        // handle both / and : (for SSH)
        return url.split(/[\/:]/).pop();
    }
}
