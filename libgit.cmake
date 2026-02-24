# ========== EMBEDDED LIBGIT2 & DEPENDENCIES SETUP ==========

set(ZLIB_ROOT "${THIRD_PARTY_DIR}/zlib")
set(OPENSSL_ROOT "${THIRD_PARTY_DIR}/openssl")
set(LIBSSH2_ROOT "${THIRD_PARTY_DIR}/libssh2")
set(LIBGIT2_ROOT "${THIRD_PARTY_DIR}/libgit2")

if (WIN32)
    set(PLATFORM "Windows")
elseif (LINUX)
    set(PLATFORM "Linux")
endif()


set(LIBGIT2_LIBRARY "${LIBGIT2_ROOT}/lib/${PLATFORM}/libgit2.a")
set(LIBSSH2_LIBRARY "${LIBSSH2_ROOT}/lib/${PLATFORM}/libssh2.a")
set(ZLIB_LIBRARY    "${ZLIB_ROOT}/lib/${PLATFORM}/libz.a")
set(SSL_LIBRARY     "${OPENSSL_ROOT}/lib/${PLATFORM}/libssl.a")
set(CRYPTO_LIBRARY  "${OPENSSL_ROOT}/lib/${PLATFORM}/libcrypto.a")

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
        rt
        m
    )
endif()

# Status Messages for Debugging
message(STATUS "--- GitEase Dependency Info ---")
message(STATUS "Libgit2 path: ${LIBGIT2_LIBRARY}")
message(STATUS "Libssh2 path: ${LIBSSH2_LIBRARY}")
message(STATUS "OpenSSL path: ${SSL_LIBRARY}")

# ========== END SETUP ==========
