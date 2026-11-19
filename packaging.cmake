set(CPACK_PACKAGE_NAME "GitEase")
set(CPACK_PACKAGE_VENDOR "GitEase Team")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "A powerful Git GUI client")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION_SHORT})
set(CPACK_PACKAGE_CONTACT "info@rasna.io")

if(UNIX AND NOT APPLE)
    set(CPACK_GENERATOR "DEB;TGZ")
    if(EXISTS "/usr/bin/rpmbuild")
        set(CPACK_GENERATOR "${CPACK_GENERATOR};RPM")
    endif()
    set(CPACK_PACKAGE_NAME "GitEase")
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
    set(CPACK_GENERATOR "DEB")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "GitEase Team <info@rasna.io>")
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS OFF)

    set(GITEASE_MIN_GLIBC "2.34" CACHE STRING "Minimum glibc version for the .deb")
    # Qt itself is bundled by qt_generate_deploy_qml_app_script; these are the system libs the
    # bundled Qt and GitEase link against (see Qt "Qt for Linux - Requirements").
    # Every name here must exist on all supported distros (Ubuntu 20.04+, Debian 11+);
    # Scripts/docker/test-deb.sh installs the .deb on each of them to check that.
    # Names that changed are given as alternatives (the 64-bit time_t "t64" renames).
    set(_gitease_depends
        "libc6 (>= ${GITEASE_MIN_GLIBC})"
        libstdc++6
        libgcc-s1
        zlib1g
        libbz2-1.0
        liblzma5
        libgssapi-krb5-2
        "libglib2.0-0t64 | libglib2.0-0"
        libdbus-1-3
        libfontconfig1
        libfreetype6
        libgl1
        libegl1
        libopengl0
        libx11-6
        libx11-xcb1
        libxkbcommon0
        libxkbcommon-x11-0
        libxcb1
        libxcb-glx0
        libxcb-randr0
        libxcb-render0
        libxcb-shape0
        libxcb-shm0
        libxcb-sync1
        libxcb-xfixes0
    )
    if(NOT GITEASE_BUNDLE_XCB_LIBS)
        list(APPEND _gitease_depends
            libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0
            libxcb-util1 libxcb-xinerama0 libxcb-xkb1)
    endif()
    list(JOIN _gitease_depends ", " CPACK_DEBIAN_PACKAGE_DEPENDS)
    set(CPACK_DEBIAN_FILE_NAME "GitEase-${PROJECT_VERSION}-linux-glibc${GITEASE_MIN_GLIBC}-amd64.deb")

    set(CPACK_RPM_PACKAGE_LICENSE "MIT") 
    set(CPACK_RPM_PACKAGE_GROUP "Development/Tools")
endif()

include(CPack)

# After (make) project, then should run (cpack) to generate .deb and .rpm and .tar.gz
