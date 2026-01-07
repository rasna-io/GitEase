set(SOURCES_BACKEND
    # Src/Git/GitWrapperCPP.cpp
    Src/Utilities/windowsManager/borderlesswindowhelper.cpp
    Src/Utilities/FileManager/FileIO.cpp

    Src/Git/IGitController.cpp
    Src/Git/GitRepository.cpp
    Src/Git/GitResult.cpp
    Src/Git/GitUtils.cpp
    Src/Git/GitBranch.cpp
    Src/Git/GitCommit.cpp
    Src/Git/GitStatus.cpp
    Src/Git/GitRemote.cpp

    Src/Git/Models/Remote.cpp
    Src/Git/Models/Commit.cpp
    Src/Git/Models/GitDiff.cpp
    Src/Git/Models/GitFileStatus.cpp
    Src/Git/Models/Repository.cpp
)

set(HEADERS_BACKEND
    # Src/Git/GitWrapperCPP.h
    Src/Utilities/windowsManager/windowcontroller.hpp
    Src/Utilities/windowsManager/borderlesswindowhelper.h
    Src/Utilities/FileManager/FileIO.hpp

    Src/Git/IGitController.h
    Src/Git/GitRepository.h
    Src/Git/GitResult.h
    Src/Git/GitUtils.h
    Src/Git/GitBranch.h
    Src/Git/GitCommit.h
    Src/Git/GitStatus.h
    Src/Git/GitRemote.h

    Src/Git/Models/Remote.h
    Src/Git/Models/Commit.h
    Src/Git/Models/GitDiff.h
    Src/Git/Models/GitFileStatus.h
    Src/Git/Models/Repository.h

)

set(INCLUDE_DIRS_BACKEND
    ${CMAKE_SOURCE_DIR}/Src/Git/Models
    ${CMAKE_SOURCE_DIR}/Src/Utilities/FileManager/
    ${CMAKE_SOURCE_DIR}/Src/Utilities/
    ${CMAKE_SOURCE_DIR}/Src
    ${CMAKE_SOURCE_DIR}/Src/Git/
)

#Add libgit2 include path to all backend files
include_directories(${INCLUDE_DIRS_BACKEND})
