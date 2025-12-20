set(SOURCES_BACKEND

)

set(HEADERS_BACKEND

)

set(INCLUDE_DIRS_BACKEND
    ${CMAKE_SOURCE_DIR}/Src/Utilities/
    ${CMAKE_SOURCE_DIR}/Src
)

#Add libgit2 include path to all backend files
include_directories(${LIBGIT2_INCLUDE_DIR})
