# ========== EMBEDDED LIBGIT2 SETUP ==========

set(LIBSSH2_ROOT "${THIRD_PARTY_DIR}/libssh2")
set(LIBSSH2_INCLUDE_DIR "${LIBSSH2_ROOT}/include")


set(LIBGIT2_ROOT "${THIRD_PARTY_DIR}/libgit2")
set(LIBGIT2_INCLUDE_DIR "${LIBGIT2_ROOT}/include")
if (MINGW)
    set(LIBSSH2_LIBRARY "${LIBSSH2_ROOT}/lib/Windows/libssh2.a")
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


add_library(libssh2 STATIC IMPORTED GLOBAL)
set_target_properties(libssh2 PROPERTIES
    IMPORTED_LOCATION "${LIBSSH2_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBSSH2_INCLUDE_DIR}"
)

add_library(libgit2 STATIC IMPORTED GLOBAL)
set_target_properties(libgit2 PROPERTIES
    IMPORTED_LOCATION "${LIBGIT2_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBGIT2_INCLUDE_DIR}"
)

target_link_libraries(libgit2 INTERFACE libssh2)

message(STATUS "Using embedded libgit2:")
message(STATUS "  Include: ${LIBGIT2_INCLUDE_DIR}")
message(STATUS "  Library: ${LIBGIT2_LIBRARY}")

if (MINGW) # MinGW static libgit2 dependencies
    target_link_libraries(libgit2 INTERFACE
        ${THIRD_PARTY_DIR}/openssl/lib/libssl.a
        ${THIRD_PARTY_DIR}/openssl/lib/libcrypto.a
        ${THIRD_PARTY_DIR}/libssh2/lib/Windows/libssh2.a
        ${THIRD_PARTY_DIR}/zlib/lib/libz.a
        ws2_32
        secur32
        crypt32
        bcrypt
        winhttp
        rpcrt4
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
