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

    // Random color assignment for repositories.
    readonly property var repoColorPalette: [
        "#aaFF1744", // neon red
        "#aaFF9100", // vivid orange
        "#aaFFD600", // bright yellow
        "#aa00E676", // neon green
        "#aa00B0FF", // bright cyan-blue
        "#aa2979FF", // vivid blue
        "#aa651FFF", // electric indigo
        "#aaD500F9", // neon purple
        "#aaFF4081", // hot pink
        "#aa1DE9B6", // bright teal
        "#aa76FF03", // lime
        "#aaF50057"  // magenta
    ]

    function randomRepoColor() {
        if (!root.repoColorPalette || root.repoColorPalette.length === 0)
            return "#4E79A7"
        const idx = Math.floor(Math.random() * root.repoColorPalette.length)
        return root.repoColorPalette[idx]
    }

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
            createRepositoryComponent(path + "/" + repoName, repoName)
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
                    name: name,
                    color: randomRepoColor()
                })
                
                // Add to repositories array
                appModel.repositories.push(repo)
                appModel.repositories = appModel.repositories.slice(0)
            }
        }

        selectRepository(repo.id)
    }

    /**
     * Select a repository by ID and update current repository state
     */
    function selectRepository(repoId :string) {
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

    /**
     * Get Commits
     */
    function getCommits(repo :Repository, limit = 100, offset = 0) : var {
        var commits = GitService.getCommits(repo.path, limit, offset)
        if (commits && commits.length > 0){
            return commits
        }

        return []
    }

    /**
     * Get All Branches
     */
    function getBranches(repo :Repository) : var {
        var branches = GitService.getBranches(repo.path)
        if (branches && branches.length > 0){
            return branches
        }

        return []
    }

    /**
     * Get Commit Detail
     * Wrapper around GitService.getCommit(hash)
     */
    function getCommitDetail(commitHash :string) : var {
        var result = GitService.getCommit(commitHash)
        if (result && result.success) {
            return result.data
        }
        return null
    }
}
