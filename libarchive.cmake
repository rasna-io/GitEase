# ========== EMBEDDED LIBARCHIVE SETUP ==========

set(LIBARCHIVE_ROOT "${THIRD_PARTY_DIR}/libarchive")

if (APPLE)
    # Built statically (BUILD_SHARED_LIBS=OFF, LZ4/ZSTD/LZO disabled to avoid a
    # Homebrew-only dylib dependency creeping in) against zlib/bz2/lzma/iconv
    # from the macOS SDK, so it needs no runtime deployment step like the
    # Windows DLL below.
    set(LIBARCHIVE_LIB "${LIBARCHIVE_ROOT}/lib/Darwin/libarchive.a")

    add_library(libarchive STATIC IMPORTED GLOBAL)
    set_target_properties(libarchive PROPERTIES
        IMPORTED_LOCATION             "${LIBARCHIVE_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${LIBARCHIVE_ROOT}/include"
    )
    target_link_libraries(libarchive INTERFACE z bz2 lzma iconv xml2)

    message(STATUS "libarchive lib : ${LIBARCHIVE_LIB}")
else()
    set(LIBARCHIVE_DLL "${LIBARCHIVE_ROOT}/bin/archive.dll")
    set(LIBARCHIVE_LIB "${LIBARCHIVE_ROOT}/lib/archive.lib")

    add_library(libarchive SHARED IMPORTED GLOBAL)
    set_target_properties(libarchive PROPERTIES
        IMPORTED_LOCATION             "${LIBARCHIVE_DLL}"
        IMPORTED_IMPLIB               "${LIBARCHIVE_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${LIBARCHIVE_ROOT}/include"
    )

    message(STATUS "libarchive DLL : ${LIBARCHIVE_DLL}")
    message(STATUS "libarchive lib : ${LIBARCHIVE_LIB}")
endif()

# ========== END SETUP ==========
