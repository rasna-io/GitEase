import QtQuick

import GitEase

/*! ***********************************************************************************************
 * RepositoryController
 * Manages repository operations including opening, cloning, and selecting repositories.
 * Handles repository lifecycle and maintains recent repositories list.
 * ************************************************************************************************/
GitRepository {
    id : root

    /* Property Declarations
     * ****************************************************************************************/
    required property            AppModel                         appModel
    property                     NotificationController           notificationController: null

    property int maxRecentLength:   10
    property var activeClones:      ({})
    property var usedRepoColors:    ({})

    readonly property var repoColorPalette: [
        "#D13B3B", "#2155D1", "#7ED108", "#D143BF", "#15D1B2",
        "#F0A043", "#5926F0", "#13F00A", "#F04D83", "#189FF0",
        "#ADB833", "#971DB8", "#07B85F", "#B8553B", "#1220B8",
        "#8AFA46", "#FA28B4", "#0AF0FA", "#FACF50", "#8019FA",
        "#3BD153", "#D12138", "#085DD1", "#A8D143", "#D115D1",
        "#43F0BD", "#F07A26", "#260AF0", "#68F04D", "#F0187C",
        "#3397B8", "#B8B11D", "#7C07B8", "#3BB869", "#B81F12",
        "#466CFA", "#92FA28", "#FA0AC9", "#50FAEB", "#FAA419",
        "#6C3BD1", "#21D128", "#D1083C", "#4391D1", "#B3D115",
        "#D943F0", "#26F09B", "#F04B0A", "#4D4EF0", "#58F018",
        "#B83381", "#1DA5B8", "#B89907", "#7E3BB8", "#12B83B",
        "#FA464F", "#286FFA", "#A2FA0A", "#FA50ED", "#19FAC9",
        "#D1853B", "#4521D1", "#1BD108", "#D14379", "#1594D1",
        "#EAF043", "#BC26F0", "#0AF071", "#F0664D", "#1835F0",
        "#6CB833", "#B81D8C", "#07B8B6", "#B8923B", "#5612B8",
        "#46FA5B", "#FA284D", "#0A7AFA", "#D1FA50", "#EE19FA",
        "#3BD19D", "#D16121", "#1708D1", "#62D143", "#D11575",
        "#43CEF0", "#F0DD26", "#970AF0", "#4DF081", "#F01E18",
        "#3356B8", "#73B81D", "#B8079C", "#3BB8A6", "#B87112",
        "#7846FA", "#2BFA28", "#FA0A53", "#50B5FA", "#E1FA19",
        "#B63BD1", "#21D17E", "#D13808", "#434BD1", "#56D115",
        "#F043B1", "#26E2F0", "#F0BD0A", "#9C4DF0", "#18F042",
        "#B83340", "#1D59B8", "#7FB807", "#B83BB4", "#12B88C",
        "#FA9646", "#4828FA", "#2CFA0A", "#FA5099", "#19BCFA",
        "#D1CF3B", "#9B21D1", "#08D159", "#D15243", "#1537D1",
        "#95F043", "#F026C1", "#0AF0E2", "#F0B74D", "#6518F0",
        "#33B83C", "#B81D40", "#0762B8", "#A0B83B", "#A712B8",
        "#46FAB3", "#FA6A28", "#100AFA", "#7DFA50", "#FA1997",
        "#3BBBD1", "#D1B821", "#7A08D1", "#43D16A", "#D11518",
        "#4379F0", "#A0F026", "#F00AD7", "#4DF0D1", "#F08918",
        "#5233B8", "#27B81D", "#B80746", "#3B8BB8", "#ADB812",
        "#D146FA", "#28FA8D", "#FA370A", "#5062FA", "#72FA19",
        "#D13BA2", "#21CDD1", "#D19B08", "#8143D1", "#15D130",
        "#F0435C", "#267FF0", "#B2F00A", "#EC4DF0", "#18F0AC",
        "#B86833", "#2D1DB8", "#29B807", "#B83B77", "#1292B8",
        "#FAEE46", "#AF28FA", "#0AFA5E", "#FA5A50", "#194DFA",
        "#89D13B", "#D121B1", "#08D1BC", "#D19843", "#4F15D1",
        "#43F046", "#F0265E", "#0A8CF0", "#D8F04D", "#CF18F0",
        "#33B87D", "#B8471D", "#070CB8", "#62B83B", "#B81277",
        "#46E8FA", "#FAD228", "#860AFA", "#50FA76", "#FA1928"
    ]

    enum GitProtocol {
        Unknown = 0,
        SSH = 1,
        HTTP = 2,
        HTTPS = 3
    }

    /* Signals
     * ****************************************************************************************/
    signal repositorySelected(Repository repo)

    /* Functions
     * ****************************************************************************************/
    function repoColor(key) {
        var text = key ? String(key) : ""
        var hash = 0
        for (var i = 0; i < text.length; ++i)
            hash = ((hash << 5) - hash + text.charCodeAt(i)) | 0
        return root.repoColorPalette[Math.abs(hash) % root.repoColorPalette.length]
    }

    function isValidRepoColor(c) {
        if (!c)
            return false
        var color = String(c).toLowerCase()
        return color !== "" && color !== "transparent" && color !== "#00000000"
    }

    function normalizeRepoPath(path) {
        var normalized = (path || "").replace(/\\/g, "/").toLowerCase()
        while (normalized.length > 1 && normalized.endsWith("/"))
            normalized = normalized.slice(0, -1)
        return normalized
    }

    function colorKey(color) {
        return String(color).toLowerCase()
    }

    function refreshUsedRepoColors() {
        var used = ({})
        var lists = [root.appModel.repositories || [], root.appModel.recentRepositories || []]

        for (var listIndex = 0; listIndex < lists.length; ++listIndex) {
            var list = lists[listIndex]
            for (var i = 0; i < list.length; ++i) {
                var value = list[i] && list[i].color
                if (root.isValidRepoColor(value))
                    used[root.colorKey(value)] = true
            }
        }

        root.usedRepoColors = used
    }

    function randomUnusedRepoColor() {
        root.refreshUsedRepoColors()
        var available = root.repoColorPalette.filter(function(color) {
            return !root.usedRepoColors[root.colorKey(color)]
        })

        if (available.length === 0)
            return root.repoColorPalette[Math.floor(Math.random() * root.repoColorPalette.length)]

        return available[Math.floor(Math.random() * available.length)]
    }

    /**
     * Initialize a new Git repository
     */
    function gitInit(path: string):bool {
        var result = init(path)

        if(result.success){
            createRepositoryComponent(path)
        }

        return result.success
    }

    /**
     * Open an existing repository at the specified path
     */
    function openRepository(path :string) : bool {
        var result = open(path)

        if(result.success){
            createRepositoryComponent(path)
        }

        return result.success
    }

    /**
     * Clone a repository from URL to the specified local path
     */
    function cloneRepository(path, url) : bool {
        let result = ({success: false})
        let repoName = extractRepoName(url)
        let protocol = detectGitProtocol(url)

        if(path && path.slice(-1) !== "/")
            path = path + "/"

        let clonedPath = path + repoName
        if (protocol === RepositoryController.GitProtocol.Unknown) {
            if(notificationController)
                notificationController.error(`Unsupported Git URL: ${url}`)
            return result
        }

        if (root.activeClones[clonedPath]) {
            if(notificationController)
                notificationController.warning(`Clone already in progress: ${clonedPath}`)
            return result
        }

        if (protocol === RepositoryController.GitProtocol.SSH)
            result = clone(url, clonedPath)
        else if (protocol === RepositoryController.GitProtocol.HTTP || protocol === RepositoryController.GitProtocol.HTTPS) {
            result = clone(url, clonedPath, "")
        }

        root.activeClones[clonedPath] = result.success

        return result
    }

    onCloneFinished: function(result) {
        root.activeClones[result.path] = false

        if(result.success) {
            let repoName = result.path.split(/[\/:]/).pop()
            createRepositoryComponent(result.path, repoName)
        }
    }

    function closeRepo(path) {
        const normalizedPath = root.normalizeRepoPath(path)
        const idx = root.appModel.repositories.findIndex(repo =>
            repo && root.normalizeRepoPath(repo.path) === normalizedPath
        )
        if (idx < 0)
            return

        root.appModel.repositories.splice(idx, 1)
        root.appModel.repositories = root.appModel.repositories.slice()

        selectRepository(root.appModel.repositories[0].id)
    }

    /**
     * Create and initialize a Repository component for the given path
     */
    function createRepositoryComponent(path, name = "") {
        // Check if already exists
        var normalizedPath = root.normalizeRepoPath(path)
        var repo = appModel.repositories.find(r =>
            r && root.normalizeRepoPath(r.path) === normalizedPath
        )
        if (!repo){
            // Create new repository
            var repoComponent = Qt.createComponent("qrc:/GitEase/Qml/Core/Models/Repository.qml")
            if (repoComponent.status === Component.Ready) {

                var savedRepo = (appModel.recentRepositories || []).find(r =>
                    r && root.normalizeRepoPath(r.path) === normalizedPath
                )

                if (name === "")
                    name = path.split('/').pop() || path.split('\\').pop() || "Repository"

                repo = repoComponent.createObject(root, {
                    id: "repo_" + Date.now(),
                    path: path,
                    name: name,
                    color: (savedRepo && root.isValidRepoColor(savedRepo.color))
                           ? savedRepo.color
                           : root.randomUnusedRepoColor()
                })
                
                // Add to repositories array
                repo.cppObjectPtr = root.currentRepo
                
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
            if (repo.cppObjectPtr) {
                root.currentRepo = repo.cppObjectPtr
            } else {
                var result = open(repo.path)
                
                if (!result.success) {
                    if(notificationController){
                        notificationController.error(result.errorMessage || "Failed to repository changes", "Repository Error", 5000)
                    }
                    return
                }
                
                repo.cppObjectPtr = root.currentRepo
            }
            
            appModel.currentRepository = repo
            root.repositorySelected(repo)

            updateRecentRepositories(repo)
            appModel.recentRepositories = appModel.recentRepositories.slice()
            appModel.save()

            if(notificationController && root.appModel.repositories.length > 1){
                notificationController.success("Changes Repository successfully", "Repository", 3000)
            }
        }else{
            if(notificationController){
                notificationController.error("Failed to repository changes", "Repository Error", 5000)
            }
        }
    }

    function updateRecentRepositories(repo) {
        if (!appModel.recentRepositories)
            appModel.recentRepositories = []

        if (!repo || !repo.path)
            return appModel.recentRepositories

        const targetPath = root.normalizeRepoPath(repo.path)

        // remove duplicates
        appModel.recentRepositories = appModel.recentRepositories.filter(r =>
            r && root.normalizeRepoPath(r.path) !== targetPath
        )

        // add to end (newest last)
        appModel.recentRepositories.unshift(repo)
        // add repo path in history
        let exists = root.appModel.repositoriesHistory.indexOf(repo.path)
        if(exists == -1) {
            appModel.repositoriesHistory.unshift(repo.path)
            appModel.repositoriesHistory = appModel.repositoriesHistory.slice()
        }

        // trim to max length
        if (root.maxRecentLength && appModel.recentRepositories.length > root.maxRecentLength) {
            appModel.recentRepositories = appModel.recentRepositories.slice(appModel.recentRepositories.length - root.maxRecentLength)
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
