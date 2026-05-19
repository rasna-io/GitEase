set(CPACK_PACKAGE_NAME "GitEase")
set(CPACK_PACKAGE_VENDOR "GitEase Team")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "A powerful Git GUI client")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION_SHORT})
set(CPACK_PACKAGE_CONTACT "yasinfaraji100@gmail.com")

if(UNIX AND NOT APPLE)
    set(CPACK_GENERATOR "DEB;TGZ")
    if(EXISTS "/usr/bin/rpmbuild")
        set(CPACK_GENERATOR "${CPACK_GENERATOR};RPM")
    endif()

    set(CPACK_PACKAGE_NAME "GitEase")
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
    set(CPACK_GENERATOR "DEB")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "GitEase Maintainer")
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS OFF)
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "git")

    set(CPACK_RPM_PACKAGE_LICENSE "MIT") 
    set(CPACK_RPM_PACKAGE_GROUP "Development/Tools")
endif()

include(CPack)

# After (make) project, then should run (cpack) to generate .deb and .rpm and .tar.gz