# After a plugin shared library is built: copy the DLL into PLUGIN_DIR/lib
# (matching plugin.json cppEntry) and write <slug>-<version>.gep next to plugin.json.
#
#   include("${CMAKE_CURRENT_SOURCE_DIR}/../PackageGep.cmake")
#   gitease_package_gep(<target>)

find_package(Python3 COMPONENTS Interpreter QUIET)
if(NOT Python3_Interpreter_FOUND)
    find_program(Python3_EXECUTABLE NAMES python3 python)
endif()

function(gitease_package_gep target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "gitease_package_gep: unknown target '${target}'")
    endif()

    set(_plugin_dir "${CMAKE_CURRENT_SOURCE_DIR}")
    set(_script "${_plugin_dir}/../../Scripts/create_gep.py")

    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_plugin_dir}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:${target}>"
            "${_plugin_dir}/lib/"
        COMMENT "Copying ${target} → ${_plugin_dir}/lib"
        VERBATIM
    )

    if(NOT Python3_EXECUTABLE)
        message(WARNING
            "Python not found — ${target} will not produce a .gep on build. "
            "Install Python 3 and reconfigure CMake.")
        return()
    endif()

    if(NOT EXISTS "${_script}")
        message(WARNING "create_gep.py not found at ${_script} — skipping .gep")
        return()
    endif()

    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND "${Python3_EXECUTABLE}" "${_script}" "${_plugin_dir}"
        COMMENT "Packaging ${target} .gep"
        VERBATIM
    )
endfunction()
