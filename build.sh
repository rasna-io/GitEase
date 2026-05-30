#!/bin/bash

set -e

source_dir=$(pwd)
build_dir="$source_dir/build/release"

# ========== Clean build folder ==========
echo " ======= [Cleaning] ======= "
if [ -d "$build_dir" ]; then
    echo "Removing existing build directory: $build_dir"
    rm -rf "$build_dir"
fi
echo "Build directory cleaned"

# ========== Version Configuration ==========
# Get version from CMakeLists.txt or set manually
if [ -f "$source_dir/CMakeLists.txt" ]; then
    # Extract version from project(VERSION x.x) in CMakeLists.txt
    VERSION=$(grep -oP 'project\([^)]*VERSION\s+\K[0-9.]+' "$source_dir/CMakeLists.txt" | head -1)
fi

# Fallback if not found
VERSION="${VERSION:-0.1.0}"

# Extract major.minor for directory naming
VERSION_SHORT=$(echo "$VERSION" | cut -d. -f1,2)

# ========== Find Latest Qt ==========
find_latest_qt() {
    # Find the newest Qt directory in common locations
    qt_library_path=$(find "$HOME/Qt" "/opt/Qt" -maxdepth 2 -type d -name "gcc_64" 2>/dev/null | \
                      sort -V | \
                      tail -1 | \
                      sed 's|/gcc_64$||')
    
    # Check environment variable override
    if [ -n "$QT_PATH" ] && [ -d "$QT_PATH" ]; then
        qt_library_path="$QT_PATH"
    fi
    
    # Verify qt was founded
    if [ -z "$qt_library_path" ]; then
        echo "ERROR: No Qt found in $HOME/Qt or /opt/Qt"
        echo "Set QT_PATH environment variable to your Qt installation"
        return 1
    fi
    
    echo "Using Qt: $qt_library_path"
    return 0
}

configure_environment() {
    export PATH="$qt_library_path/gcc_64/bin:$PATH"
    export LD_LIBRARY_PATH="$qt_library_path/gcc_64/lib:$LD_LIBRARY_PATH"
    echo "Using Qt from: $qt_library_path"
}

run_cmake() {
    echo " ======= [CMake Configure] ======= "
    cmake -S "$source_dir" -B "$build_dir" \
        -DCMAKE_PREFIX_PATH="$qt_library_path/gcc_64" \
        -DCMAKE_BUILD_TYPE=Release 
}

build_project() {
    echo " ======= [Building] ======= "
    jobs=$(( $(nproc) - 2 ))
    jobs=$(( jobs > 0 ? jobs : 1 ))
    cmake --build "$build_dir" -j"$jobs"
}

build_package() {
    echo " ======= [Packaging] ======= "
    cmake --build "$build_dir" --target package
}

# ========== Run Steps ==========

configure_environment
find_latest_qt
run_cmake
build_project
build_package
