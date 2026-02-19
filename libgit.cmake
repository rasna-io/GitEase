# ========== EMBEDDED LIBGIT2 & DEPENDENCIES SETUP ==========

set(ZLIB_ROOT "${THIRD_PARTY_DIR}/zlib")
set(OPENSSL_ROOT "${THIRD_PARTY_DIR}/openssl")
set(LIBSSH2_ROOT "${THIRD_PARTY_DIR}/libssh2")
set(LIBGIT2_ROOT "${THIRD_PARTY_DIR}/libgit2")

if (MINGW)
    set(LIBSSH2_LIBRARY "${LIBSSH2_ROOT}/lib/Windows/libssh2.a")
    set(LIBGIT2_LIBRARY "${LIBGIT2_ROOT}/lib/Windows/libgit2.a")
    set(ZLIB_LIBRARY    "${ZLIB_ROOT}/lib/libz.a")
    set(SSL_LIBRARY     "${OPENSSL_ROOT}/lib/libssl.a")
    set(CRYPTO_LIBRARY  "${OPENSSL_ROOT}/lib/libcrypto.a")
elseif(UNIX)
    set(LIBGIT2_LIBRARY "${LIBGIT2_ROOT}/lib/Linux/libgit2.a")
    set(LIBSSH2_LIBRARY "${LIBSSH2_ROOT}/lib/Linux/libssh2.a")
    set(ZLIB_LIBRARY    "${ZLIB_ROOT}/lib/Linux/libz.a")
    set(SSL_LIBRARY     "${OPENSSL_ROOT}/lib/Linux/libssl.a")
    set(CRYPTO_LIBRARY  "${OPENSSL_ROOT}/lib/Linux/libcrypto.a")
endif()

# Define Imported Libraries
add_library(libssh2 STATIC IMPORTED GLOBAL)
set_target_properties(libssh2 PROPERTIES
    IMPORTED_LOCATION "${LIBSSH2_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBSSH2_ROOT}/include"
)

add_library(libgit2 STATIC IMPORTED GLOBAL)
set_target_properties(libgit2 PROPERTIES
    IMPORTED_LOCATION "${LIBGIT2_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBGIT2_ROOT}/include"
)

# Link Dependencies
if (MINGW)
    target_link_libraries(libgit2 INTERFACE
        libssh2
        "${SSL_LIBRARY}"
        "${CRYPTO_LIBRARY}"
        "${ZLIB_LIBRARY}"
        ws2_32 secur32 crypt32 bcrypt winhttp rpcrt4
    )
elseif(UNIX)
    target_link_libraries(libgit2 INTERFACE
        libssh2
        "${SSL_LIBRARY}"
        "${CRYPTO_LIBRARY}"
        "${ZLIB_LIBRARY}"
        gssapi_krb5
        krb5
        k5crypto
        com_err
        pthread
        dl
    )
endif()

# Status Messages for Debugging
message(STATUS "Libgit2 Linux Path: ${LIBGIT2_LIBRARY}")
message(STATUS "Libssh2 Linux Path: ${LIBSSH2_LIBRARY}")

# ========== END SETUP ==========
