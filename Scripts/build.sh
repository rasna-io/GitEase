#!/bin/bash

set -e

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# BUILD_DIR / THIRD_PARTY_DIR may be set by Scripts/docker-build.sh
build_dir="${BUILD_DIR:-$source_dir/build/release}"

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
    # Find the newest Qt directory in common locations, or the one picked with --qt <version>
    local find_filter=(-name "gcc_64")
    if [ -n "$qt_version" ]; then
        find_filter=(-path "*/$qt_version/gcc_64")
    fi

    qt_library_path=$(find "$HOME/Qt" "/opt/Qt" -maxdepth 2 -type d "${find_filter[@]}" 2>/dev/null | \
                      sort -V | \
                      tail -1 | \
                      sed 's|/gcc_64$||')

    # Check environment variable override
    if [ -n "$QT_PATH" ] && [ -d "$QT_PATH" ]; then
        qt_library_path="$QT_PATH"
    fi

    # Verify qt was founded
    if [ -z "$qt_library_path" ]; then
        echo "ERROR: No Qt${qt_version:+ $qt_version} found in $HOME/Qt or /opt/Qt"
        echo "Set QT_PATH environment variable to your Qt installation"
        return 1
    fi

    echo "Using Qt: $qt_library_path"
    return 0
}

# Oldest Qt that GitEase builds with:
#   qt_add_qml_module         -> 6.2 (documented)
#   qt_generate_deploy_*      -> 6.3 (documented)
#   QtQuick.Effects MultiEffect (PopupDialog.qml, PagesRail.qml) -> 6.5 (not stated in the docs, from memory)
# Also needs the "Qt 5 Compatibility Module" (Core5Compat) installed with Qt.
min_qt_version="6.5.0"

# Derive the Qt version from the install directory name (e.g. ~/Qt/6.5.3 -> 6.5.3)
check_qt_version() {
    qt_version=$(basename "$qt_library_path")
    if ! echo "$qt_version" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
        echo "WARNING: cannot read the Qt version from '$qt_library_path'; skipping version checks."
        qt_version=""
        return 0
    fi

    if [ "$(printf '%s\n%s\n' "$qt_version" "$min_qt_version" | sort -V | head -1)" != "$min_qt_version" ]; then
        echo "ERROR: Qt $qt_version is too old; GitEase needs Qt $min_qt_version or newer."
        return 1
    fi
    echo "Qt version: $qt_version"
}

# glibc that Qt's own Linux binaries need, by Qt version.
#   6.10+ -> 2.34 (documented, "Supported Glibc Versions")
#   6.7-6.9 -> 2.28 (documented)
#   6.5-6.6 -> 2.28 is an assumption; the docs do not state it. verify_glibc checks the real number.
qt_glibc_floor() {
    if [ -z "$qt_version" ]; then
        echo "2.34"
    elif [ "$(printf '%s\n%s\n' "$qt_version" "6.10" | sort -V | head -1)" = "6.10" ]; then
        echo "2.34"
    else
        echo "2.28"
    fi
}

resolve_glibc() {
    local qt_floor
    qt_floor=$(qt_glibc_floor)
    min_glibc="${min_glibc:-$qt_floor}"

    if [ "$(printf '%s\n%s\n' "$min_glibc" "$qt_floor" | sort -V | tail -1)" != "$min_glibc" ]; then
        echo "ERROR: --glibc $min_glibc is below the $qt_floor that Qt ${qt_version:-6.x} needs."
        return 1
    fi

    # Binaries only run on distros with glibc >= the one they were built against,
    # so the build host must not be newer than the declared minimum.
    local host_glibc
    host_glibc=$(ldd --version | head -1 | grep -oE '[0-9]+\.[0-9]+$')
    echo "Target glibc: >= $min_glibc (Qt floor $qt_floor, build host has $host_glibc)"
    if [ "$(printf '%s\n%s\n' "$host_glibc" "$min_glibc" | sort -V | tail -1)" != "$min_glibc" ]; then
        echo "WARNING: build host glibc ($host_glibc) is newer than the target ($min_glibc)."
        echo "         The result may fail verification; build on the oldest target distro."
    fi
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
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        ${THIRD_PARTY_DIR:+-DTHIRD_PARTY_DIR="$THIRD_PARTY_DIR"} \
        -DGITEASE_MIN_GLIBC="$min_glibc"
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

# Fail if any binary inside the .deb needs a newer glibc than the one the
# package declares in its "Depends: libc6 (>= ...)" line.
verify_glibc() {
    echo " ======= [Verifying glibc >= $min_glibc] ======= "
    local deb extract_dir worst=""
    deb=$(ls -t "$build_dir"/*.deb 2>/dev/null | head -1)
    if [ -z "$deb" ]; then
        echo "ERROR: no .deb found in $build_dir"
        return 1
    fi

    extract_dir=$(mktemp -d)
    dpkg-deb -x "$deb" "$extract_dir"

    # Highest GLIBC_x.y symbol version referenced by any ELF file in the package
    worst=$(find "$extract_dir" -type f \( -name "*.so*" -o -perm -u+x \) -print0 | \
            xargs -0 -r objdump -T 2>/dev/null | \
            grep -o 'GLIBC_[0-9][0-9.]*' | sed 's/GLIBC_//' | sort -V | tail -1)
    rm -rf "$extract_dir"

    echo "Package requires glibc: ${worst:-unknown} (declared minimum: $min_glibc)"
    if [ -n "$worst" ] && [ "$(printf '%s\n%s\n' "$worst" "$min_glibc" | sort -V | tail -1)" != "$min_glibc" ]; then
        echo "ERROR: package needs glibc $worst but declares >= $min_glibc."
        echo "Build on an older distro (e.g. Ubuntu 22.04 = glibc 2.35) or raise --glibc."
        return 1
    fi
}

usage() {
    echo "Usage: $0 [--qt <version>] [--glibc <version>]"
    echo "  --qt <version>     Qt to build with, e.g. 6.5.3 (looks in ~/Qt and /opt/Qt)."
    echo "                     Default: newest installed. Minimum supported: $min_qt_version."
    echo "                     Qt 6.1 and 6.2 are not supported (no deploy script / MultiEffect)."
    echo "  --glibc <version>  Oldest glibc the .deb must support."
    echo "                     Default: the floor of the chosen Qt (6.10+: 2.34, older: 2.28)."
    echo "                     Becomes 'Depends: libc6 (>= <version>)' and is verified"
    echo "                     against the packaged binaries. Reference points:"
    echo "                       Ubuntu 22.04 = 2.35, Debian 12 = 2.36, Ubuntu 24.04 = 2.39"
}

# ========== Arguments ==========
min_glibc="$GLIBC_MIN"
qt_version=""
while [ $# -gt 0 ]; do
    case "$1" in
        --glibc) min_glibc="$2"; shift 2 ;;
        --qt) qt_version="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1"; usage; exit 1 ;;
    esac
done

# ========== Run Steps ==========

find_latest_qt
check_qt_version
resolve_glibc
configure_environment
run_cmake
build_project
build_package
verify_glibc
