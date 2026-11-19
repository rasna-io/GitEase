#!/bin/bash
# Build the Linux .deb and the sample plugins inside Docker, then install and
# start them on several distros. Run on a Linux machine with Docker;
# Qt is downloaded into the build image, nothing else needs to be installed.
#
#   ./Scripts/docker-build.sh                       # build on ubuntu:20.04, test everywhere
#   ./Scripts/docker-build.sh --qt 6.9.3            # another Qt (6.5 - 6.9), default 6.8.3
#   ./Scripts/docker-build.sh --no-test             # build only
#   ./Scripts/docker-build.sh --test-only           # re-test the last build
#   ./Scripts/docker-build.sh --test ubuntu:22.04   # test on one image only (repeatable)
#   ./Scripts/docker-build.sh --rebuild-ext         # rebuild Ext/*/lib/Linux even if cached
#   ./Scripts/docker-build.sh --plugins-only        # rebuild only the sample plugins, keep the .deb
#
# Why Docker: a binary only runs on distros whose glibc is at least the one it
# was built against. Building in ubuntu:20.04 (glibc 2.31) gives one .deb for
# Ubuntu 20.04+ and Debian 11+. Qt is downloaded into the image (aqtinstall)
# and must run there too: Qt 6.5 - 6.9 (glibc 2.28). Qt 6.10+ needs 2.34.
#
# The sample plugins are built in the same container with the same Qt. Qt
# refuses to load a plugin built with a newer Qt than the app ("uses
# incompatible Qt library"), so plugins built against the oldest Qt we ship load
# in every GitEase build.
#
# Output: dist/linux/  (the .deb and every sample plugin's .gep)

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

base_image="ubuntu:20.04"
qt_version="6.8.3"
do_build=1
do_test=1
rebuild_ext=0
plugins_only=0
test_images=()
default_test_images=(ubuntu:20.04 ubuntu:22.04 ubuntu:24.04 ubuntu:26.04 debian:11 debian:12 debian:13)

usage() { sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
    case "$1" in
        --qt)          qt_version="$2"; shift 2 ;;
        --base)        base_image="$2"; shift 2 ;;
        --test)        test_images+=("$2"); shift 2 ;;
        --no-test)     do_test=0; shift ;;
        --test-only)   do_build=0; shift ;;
        --rebuild-ext) rebuild_ext=1; shift ;;
        --plugins-only) plugins_only=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Unknown argument: $1"; usage; exit 1 ;;
    esac
done
[ ${#test_images[@]} -gt 0 ] || test_images=("${default_test_images[@]}")

command -v docker >/dev/null || { echo "ERROR: docker is not installed"; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERROR: cannot talk to the Docker daemon (is your user in the 'docker' group?)"; exit 1; }

dist="$repo/dist/linux"
tag="$(echo "$base_image" | tr ':/' '--')"
image="gitease-build:$tag-qt$qt_version"

build() {
    case "$qt_version" in
        6.[5-9]|6.[5-9].*) ;;
        *) echo "ERROR: Qt $qt_version cannot be used: Qt 6.10+ needs glibc 2.34, Qt < 6.5 is too old."
           exit 1 ;;
    esac

    echo " ======= [Docker image $image] ======= "
    docker build -t "$image" \
        --build-arg BASE_IMAGE="$base_image" \
        --build-arg QT_VERSION="$qt_version" \
        "$repo/Scripts/docker"

    echo " ======= [Build in $base_image with Qt $qt_version] ======= "
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$repo:/src" \
        -e OUT_DIR="/src/build/docker/$tag" \
        -e DIST_DIR="/src/dist/linux" \
        -e REBUILD_EXT="$rebuild_ext" \
        -e PLUGINS_ONLY="$plugins_only" \
        "$image" bash /src/Scripts/docker/container-build.sh
}

run_tests() {
    local deb
    deb=$(ls -t "$dist"/*.deb 2>/dev/null | head -1 || true)
    if [ -z "$deb" ]; then
        echo "ERROR: no .deb in $dist; build first."
        exit 1
    fi
    echo " ======= [Testing $(basename "$deb")] ======= "

    local results=() failed=0 img log
    mkdir -p "$repo/build/docker/test-logs"
    for img in "${test_images[@]}"; do
        log="$repo/build/docker/test-logs/$(echo "$img" | tr ':/' '--').log"
        echo "--- $img (log: ${log#$repo/})"
        if docker run --rm \
                -v "$dist:/dist:ro" \
                -v "$repo/SamplePlugins:/plugins:ro" \
                -v "$repo/Scripts/docker/test-deb.sh:/test-deb.sh:ro" \
                -e DEB="/dist/$(basename "$deb")" \
                "$img" bash /test-deb.sh > "$log" 2>&1; then
            results+=("PASS  $img  $(grep '^RESULT' "$log" | cut -d' ' -f2-)")
        else
            results+=("FAIL  $img  $(grep '^RESULT' "$log" | cut -d' ' -f2- || echo 'see log')")
            failed=1
        fi
        tail -n 4 "$log" | sed 's/^/    /'
    done

    echo
    echo " ======= [Summary] ======= "
    printf '%s\n' "${results[@]}"
    return $failed
}

[ $do_build -eq 1 ] && build
[ $do_test -eq 1 ] && run_tests
echo
echo "Packages: $dist"
ls -l "$dist"
