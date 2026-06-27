# ========== EMBEDDED LIBARCHIVE SETUP ==========

set(LIBARCHIVE_ROOT "${THIRD_PARTY_DIR}/libarchive")

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

# ========== END SETUP ==========
