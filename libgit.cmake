# ========== EMBEDDED LIBGIT2 SETUP ==========

set(LIBGIT2_ROOT "${THIRD_PARTY_DIR}/libgit2")
set(LIBGIT2_INCLUDE_DIR "${LIBGIT2_ROOT}/include")
if (MINGW)
    set(LIBGIT2_LIBRARY "${LIBGIT2_ROOT}/lib/Windows/libgit2.a")
elseif(UNIX)
    set(LIBGIT2_LIBRARY "${LIBGIT2_ROOT}/lib/Linux/libgit2.a")
endif()

if(NOT EXISTS "${LIBGIT2_INCLUDE_DIR}/git2.h")
    message(FATAL_ERROR "git2.h not found at ${LIBGIT2_INCLUDE_DIR}")
endif()

if(NOT EXISTS "${LIBGIT2_LIBRARY}")
    message(FATAL_ERROR "libgit2.a not found at ${LIBGIT2_LIBRARY}")
endif()

add_library(libgit2 STATIC IMPORTED GLOBAL)

set_target_properties(libgit2 PROPERTIES
    IMPORTED_LOCATION "${LIBGIT2_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBGIT2_INCLUDE_DIR}"
)

message(STATUS "Using embedded libgit2:")
message(STATUS "  Include: ${LIBGIT2_INCLUDE_DIR}")
message(STATUS "  Library: ${LIBGIT2_LIBRARY}")

if (MINGW) # MinGW static libgit2 dependencies
    target_link_libraries(libgit2 INTERFACE
        ws2_32
        bcrypt
        crypt32
        secur32
        rpcrt4
        winhttp
        z
    )
elseif(UNIX) # UNIX static libgit2 dependencies
    target_link_libraries(libgit2 INTERFACE
        pthread
        z
        crypto
        ssl
        gssapi_krb5
        krb5
        k5crypto
        com_err
    )
endif()

# ========== END LIBGIT2 SETUP ==========
