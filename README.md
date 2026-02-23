# GitEase

A desktop Git client built with Qt/QML + C++ and powered by libgit2.

GitEase focuses on day-to-day repository operations in a native UI: repository onboarding, commit workflows, branch and remote management, stash handling, diff review, and commit graph exploration.

## Project Status

GitEase is under active development.

Current codebase includes production-oriented implementations for core Git workflows and UI pages for:
- Welcome/onboarding
- Commit workspace
- Commit graph/history exploration
- Utilities (remotes, branches, stash, bundle import/export)

## Key Features

### Repository Management
- Initialize a new repository
- Open/close local repositories
- Clone repositories
- Git protocol detection (SSH / HTTP / HTTPS)

### Commit and Changes Workflow
- View working tree status (staged, unstaged, untracked)
- Stage/unstage individual files
- Stage all changes
- Stage selected line ranges (partial/hunk-style staging)
- Revert individual files
- Revert selected lines
- Revert all unstaged changes
- Create commits
- Amend last commit
- Revert a commit

### Diff and History
- Side-by-side diff visualization
- Staged and unstaged diff views
- Commit-to-commit file diff retrieval
- Commit history retrieval with paging
- Commit details and parent navigation
- Commit graph view with filtering/navigation controls

### Branch Management
- List branches
- Create branch (from HEAD or specific commit)
- Checkout branch or detached commit
- Rename branch
- Delete branch
- Get current branch and branch lineage

### Remote Operations
- List/add/edit/remove remotes
- Fetch from remotes
- Push to remotes (with optional force)
- SSH and HTTPS auth pathways
- Upstream branch lookup

### Stash and Bundle Utilities
- Save/list/apply/pop/remove stashes
- Build complete Git bundles
- Build diff bundles
- Unbundle via libgit2 or Git CLI path

### Configuration
- Read/write Git config values at system, global, local, and worktree levels

## Tech Stack

- C++17
- Qt 6 (Core, Quick, Gui, Concurrent)
- QML (UI + controllers/models)
- libgit2 (embedded static library setup)
- OpenSSL, libssh2, zlib (linked through embedded dependencies)

## Repository Layout

```text
GitEase/
|- Src/                 # C++ backend and libgit2 integrations
|- Qml/                 # QML UI, pages, controllers, components
|- Res/                 # App resources (images/fonts/plugins)
|- Ext/                 # Embedded third-party libraries/headers
|- CMakeLists.txt       # Root build definition
|- backend.cmake        # Backend source/header aggregation
|- Resources.cmake      # QML/resource aggregation
```

## Prerequisites

Install the following:
- CMake 3.16+
- Qt 6 development kit (Qt Quick modules included)
- A C++17-compatible compiler
- Windows toolchain: MinGW (recommended by current embedded lib configuration)
- Linux toolchain: GCC or Clang
- Git (recommended; required for CLI-based unbundle path)

## Build

### 1) Configure

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

### 2) Compile

```bash
cmake --build build --config Release
```

## Run

Windows (multi-config generators):

```bash
./build/Release/GitEase.exe
```

Linux / single-config generators:

```bash
./build/GitEase
```

## Development Notes

- QML modules are bundled through `qt_add_qml_module`.
- In Debug builds, cache generation is disabled for improved QML preview behavior (`NO_CACHEGEN`).
- Embedded dependency wiring is configured in `libgit.cmake`.

## Planned Features

- Show stash entries in Graph View
- Show working tree state in Graph View
- Select all lines or multi-line ranges in Diff View
- Edit and save files directly from Diff View
- Merge support
- Conflict viewer
- Scan and list all repositories on the computer
- Fetch/Pull all repositories
- Linux installer/package
- Double-click a commit/branch to checkout
- Show diff for staged files in Graph View
- Force push from UI
- Amend commit flow improvements
- Cherry-pick support
- Show detailed fetch results and summaries

## Contributing

Contributions are welcome.

Recommended workflow:
1. Fork and create a feature branch.
2. Keep changes scoped and documented.
3. Build locally and verify affected flows.
4. Open a pull request with problem statement, proposed solution, and validation steps.

## Open-Source Notice

This repository currently does not include a `LICENSE` file. If you plan to publish or accept external contributions, add an explicit open-source license.

## Acknowledgments

- Qt for the UI framework
- libgit2 and ecosystem libraries (OpenSSL, libssh2, zlib)
