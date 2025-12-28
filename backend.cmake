set(SOURCES_BACKEND
    Src/Git/GitWrapperCPP.cpp
    Src/Utilities/windowsManager/borderlesswindowhelper.cpp
    Src/Utilities/FileManager/FileIO.cpp
)

set(HEADERS_BACKEND
    Src/Git/GitWrapperCPP.h
    Src/Utilities/windowsManager/windowcontroller.hpp
    Src/Utilities/windowsManager/borderlesswindowhelper.h
    Src/Utilities/FileManager/FileIO.hpp
)

set(INCLUDE_DIRS_BACKEND
    ${CMAKE_SOURCE_DIR}/Src/Utilities/FileManager/
    ${CMAKE_SOURCE_DIR}/Src/Utilities/
    ${CMAKE_SOURCE_DIR}/Src
    ${CMAKE_SOURCE_DIR}/Src/Git/
)

#Add libgit2 include path to all backend files
include_directories(${INCLUDE_DIRS_BACKEND})
