set(SOURCES_BACKEND
    # Src/Git/GitWrapperCPP.cpp
    Src/Utilities/windowsManager/borderlesswindowhelper.cpp
    Src/Utilities/FileManager/FileIO.cpp
    Src/Utilities/GitScanner/GitScanner.cpp

    Src/Git/IGitController.cpp
    Src/Git/GitRepository.cpp
    Src/Git/GitResult.cpp
    Src/Git/GitUtils.cpp
    Src/Git/GitBranch.cpp
    Src/Git/GitCommit.cpp
    Src/Git/GitStatus.cpp
    Src/Git/GitRemote.cpp
    Src/Git/GitRebase.cpp
    Src/Git/GitCherryPick.cpp
    Src/Git/GitBundle.cpp
    Src/Git/GitConfig.cpp
    Src/Git/GitStash.cpp
    Src/Git/GitMerge.cpp
    Src/Git/GitConflict.cpp
    Src/Git/GitTag.cpp

    Src/Git/Models/Remote.cpp
    Src/Git/Models/Commit.cpp
    Src/Git/Models/GitDiff.cpp
    Src/Git/Models/GitFileStatus.cpp
    Src/Git/Models/Repository.cpp
    Src/Git/Models/Config.cpp

    Src/Git/Auth/GitSshAuth.cpp
    Src/Git/Auth/GitHttpsAuth.cpp
    Src/Git/Utilities/GitProtocolDetector.cpp
    Src/Utilities/SshKeyManager/SshKeyManager.cpp

    Src/Plugins/PluginContext.cpp
    Src/Plugins/PluginManager.cpp
)

set(HEADERS_BACKEND
    # Src/Git/GitWrapperCPP.h
    Src/Utilities/windowsManager/windowcontroller.hpp
    Src/Utilities/windowsManager/borderlesswindowhelper.h
    Src/Utilities/FileManager/FileIO.hpp
    Src/Utilities/GitScanner/GitScanner.hpp

    Src/Git/IGitController.h
    Src/Git/GitRepository.h
    Src/Git/GitResult.h
    Src/Git/GitUtils.h
    Src/Git/GitBranch.h
    Src/Git/GitCommit.h
    Src/Git/GitStatus.h
    Src/Git/GitRemote.h
    Src/Git/GitRebase.h
    Src/Git/GitCherryPick.h
    Src/Git/GitBundle.h
    Src/Git/GitConfig.h
    Src/Git/GitStash.h
    Src/Git/GitMerge.h
    Src/Git/GitConflict.h
    Src/Git/GitTag.h

    Src/Git/Models/Remote.h
    Src/Git/Models/Commit.h
    Src/Git/Models/GitDiff.h
    Src/Git/Models/GitFileStatus.h
    Src/Git/Models/Repository.h
    Src/Git/Models/Config.h

    Src/Git/Auth/IGitAuth.h
    Src/Git/Auth/GitSshAuth.h
    Src/Git/Auth/GitHttpsAuth.h

    Src/Git/Utilities/GitProtocolDetector.h
    Src/Utilities/SshKeyManager/SshKeyManager.h

    Src/Plugins/IPluginContext.h
    Src/Plugins/IPlugin.h
    Src/Plugins/IDockPlugin.h
    Src/Plugins/ICommandPlugin.h
    Src/Plugins/IAuthPlugin.h
    Src/Plugins/IDiffPlugin.h
    Src/Plugins/IServicePlugin.h
    Src/Plugins/PluginInfo.h
    Src/Plugins/PluginContext.h
    Src/Plugins/PluginManager.h
)

set(INCLUDE_DIRS_BACKEND
    ${CMAKE_SOURCE_DIR}/Src/Git/Models
    ${CMAKE_SOURCE_DIR}/Src/Git/Utilities
    ${CMAKE_SOURCE_DIR}/Src/Utilities/FileManager/
    ${CMAKE_SOURCE_DIR}/Src/Utilities/
    ${CMAKE_SOURCE_DIR}/Src/Utilities/SshKeyManager/
    ${CMAKE_SOURCE_DIR}/Src/Utilities/GitScanner/
    ${CMAKE_SOURCE_DIR}/Src/Utilities/windowsManager/
    ${CMAKE_SOURCE_DIR}/Src
    ${CMAKE_SOURCE_DIR}/Src/Git/
    ${CMAKE_SOURCE_DIR}/Src/Plugins/
)

#Add libgit2 include path to all backend files
include_directories(${INCLUDE_DIRS_BACKEND})
