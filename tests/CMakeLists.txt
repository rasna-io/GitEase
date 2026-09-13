find_package(Qt6 REQUIRED COMPONENTS Core Test Qml)

add_library(gitease_test_support STATIC
    ${CMAKE_SOURCE_DIR}/Src/Git/Utilities/GitProtocolDetector.cpp
    ${CMAKE_SOURCE_DIR}/Src/Utilities/FileManager/FileIO.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitResult.h
)

target_include_directories(gitease_test_support PUBLIC
    ${CMAKE_SOURCE_DIR}/Src
    ${CMAKE_SOURCE_DIR}/Src/Git
    ${CMAKE_SOURCE_DIR}/Src/Git/Utilities
    ${CMAKE_SOURCE_DIR}/Src/Utilities
    ${CMAKE_SOURCE_DIR}/Src/Utilities/FileManager
)

target_link_libraries(gitease_test_support PUBLIC
    Qt6::Core
    Qt6::Qml
)

add_executable(test_git_protocol_detector
    TestGitProtocolDetector.cpp
)

target_link_libraries(test_git_protocol_detector PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_test_support
)

add_test(NAME test_git_protocol_detector COMMAND test_git_protocol_detector)

add_executable(test_file_io
    TestFileIO.cpp
)

target_link_libraries(test_file_io PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_test_support
)

add_test(NAME test_file_io COMMAND test_file_io)

add_library(gitease_git_backend_test_support STATIC
    ${CMAKE_SOURCE_DIR}/Src/Git/IGitController.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Async/GitAsyncRunner.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitResult.h
    ${CMAKE_SOURCE_DIR}/Src/Git/GitUtils.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitRepository.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitRemote.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitBranch.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitCommit.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitStatus.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitConfig.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitStash.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/GitBundle.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Auth/GitHttpsAuth.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Auth/GitSshAuth.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Utilities/GitProtocolDetector.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Models/Repository.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Models/Remote.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Models/Commit.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Models/Config.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Models/GitDiff.cpp
    ${CMAKE_SOURCE_DIR}/Src/Git/Models/GitFileStatus.cpp
    ${CMAKE_SOURCE_DIR}/Src/Utilities/SshKeyManager/SshKeyManager.cpp
)

target_include_directories(gitease_git_backend_test_support PUBLIC
    ${CMAKE_SOURCE_DIR}/Src
    ${CMAKE_SOURCE_DIR}/Src/Git
    ${CMAKE_SOURCE_DIR}/Src/Git/Auth
    ${CMAKE_SOURCE_DIR}/Src/Git/Models
    ${CMAKE_SOURCE_DIR}/Src/Git/Utilities
    ${CMAKE_SOURCE_DIR}/Src/Utilities
    ${CMAKE_SOURCE_DIR}/Src/Utilities/SshKeyManager
)

target_link_libraries(gitease_git_backend_test_support PUBLIC
    Qt6::Core
    Qt6::Qml
    Qt6::Concurrent
    libgit2
)

add_executable(test_git_remote
    TestGitRemote.cpp
)

target_link_libraries(test_git_remote PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)

add_test(NAME test_git_remote COMMAND test_git_remote)

add_executable(test_git_repository
    TestGitRepository.cpp
)
target_link_libraries(test_git_repository PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_git_repository COMMAND test_git_repository)

add_executable(test_git_branch
    TestGitBranch.cpp
)
target_link_libraries(test_git_branch PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_git_branch COMMAND test_git_branch)

add_executable(test_git_commit
    TestGitCommit.cpp
)
target_link_libraries(test_git_commit PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_git_commit COMMAND test_git_commit)

add_executable(test_git_status
    TestGitStatus.cpp
)
target_link_libraries(test_git_status PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_git_status COMMAND test_git_status)

add_executable(test_git_config
    TestGitConfig.cpp
)
target_link_libraries(test_git_config PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_git_config COMMAND test_git_config)

add_executable(test_git_stash
    TestGitStash.cpp
)
target_link_libraries(test_git_stash PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_git_stash COMMAND test_git_stash)

add_executable(test_git_bundle
    TestGitBundle.cpp
)
target_link_libraries(test_git_bundle PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_git_bundle COMMAND test_git_bundle)

add_executable(test_ssh_key_manager
    TestSshKeyManager.cpp
)
target_link_libraries(test_ssh_key_manager PRIVATE
    Qt6::Core
    Qt6::Test
    gitease_git_backend_test_support
)
add_test(NAME test_ssh_key_manager COMMAND test_ssh_key_manager)
