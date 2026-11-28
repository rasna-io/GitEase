#!/bin/bash
# Rebuild the static Linux libraries in Ext/*/lib/Linux from source:
# zlib, OpenSSL, libssh2, libgit2 and libarchive.
#
#   ./Scripts/rebuild_ext.sh               # writes into <repo>/Ext
#   ./Scripts/rebuild_ext.sh /path/to/Ext  # writes into another copy of Ext
#
# The .a files only use glibc symbols of the machine they are built on, and a
# GitEase linked against them needs at least that glibc. Built on glibc 2.38+
# they reference __isoc23_strtol & co. (GLIBC_2.38) and the app will not start
# on Ubuntu 22.04 / Debian 12 or older. Scripts/docker-build.sh runs this inside
# an ubuntu:20.04 container (glibc 2.31) for that reason.
#
# Needs: build-essential cmake perl curl zlib1g-dev libbz2-dev liblzma-dev libkrb5-dev

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT="$(cd "${1:-$script_dir/../Ext}" && pwd)"
BUILD="${EXT_BUILD_DIR:-/tmp/gitease-ext-build}"
JOBS="$(nproc)"

# Keep these in step with the headers in Ext/*/include (shared by all platforms).
ZLIB_VERSION=1.3.1
OPENSSL_VERSION=3.6.1
LIBSSH2_VERSION=1.11.1
LIBGIT2_VERSION=1.9.0
LIBARCHIVE_VERSION=3.8.11

echo "Ext:   $EXT"
echo "Build: $BUILD"
echo "glibc: $(getconf GNU_LIBC_VERSION | awk '{ print $2 }')"

mkdir -p "$BUILD" \
         "$EXT/zlib/lib/Linux" "$EXT/openssl/lib/Linux" "$EXT/libssh2/lib/Linux" \
         "$EXT/libgit2/lib/Linux" "$EXT/libarchive/lib/Linux"

# A library that finished building leaves a stamp in $BUILD, so a rerun after a
# failure (or a crash) continues with the next one. Delete $BUILD to start over.
run_step() {
    local name="$1" version="$2"
    local stamp="$BUILD/.done-$name-$version"
    if [ -f "$stamp" ]; then
        echo "======= $name $version already built (stamp $stamp) ======="
        return
    fi
    "build_$name"
    touch "$stamp"
}

# Skip already-downloaded tarballs
download_if_missing() {
    local url="$1"
    local file="$2"
    if [ -f "$BUILD/$file" ]; then
        echo "  (already downloaded: $file)"
    else
        curl -fL "$url" -o "$BUILD/$file.part"
        mv "$BUILD/$file.part" "$BUILD/$file"
    fi
}

# --- zlib ---
build_zlib() {
    echo "======= Building zlib ======="
    download_if_missing \
        "https://github.com/madler/zlib/releases/download/v$ZLIB_VERSION/zlib-$ZLIB_VERSION.tar.gz" \
        "zlib-$ZLIB_VERSION.tar.gz"
    cd "$BUILD" && rm -rf "zlib-$ZLIB_VERSION" && tar xf "zlib-$ZLIB_VERSION.tar.gz"
    cd "$BUILD/zlib-$ZLIB_VERSION"
    CFLAGS="-O2 -fPIC" ./configure --static
    make -j"$JOBS"
    cp libz.a "$EXT/zlib/lib/Linux/"
    echo "zlib done"
}

# --- openssl ---
build_openssl() {
    echo "======= Building openssl ======="
    download_if_missing \
        "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz" \
        "openssl-$OPENSSL_VERSION.tar.gz"
    cd "$BUILD" && rm -rf "openssl-$OPENSSL_VERSION" && tar xf "openssl-$OPENSSL_VERSION.tar.gz"
    cd "$BUILD/openssl-$OPENSSL_VERSION"
    # --openssldir: where Debian/Ubuntu keep openssl.cnf and the CA store.
    ./Configure linux-x86_64 no-shared no-tests -fPIC \
        --openssldir=/usr/lib/ssl \
        --with-zlib-include="$BUILD/zlib-$ZLIB_VERSION" \
        --with-zlib-lib="$EXT/zlib/lib/Linux"
    make -j"$JOBS" build_libs
    cp libssl.a libcrypto.a "$EXT/openssl/lib/Linux/"
    echo "openssl done"
}

# --- libssh2 ---
build_libssh2() {
    echo "======= Building libssh2 ======="
    download_if_missing \
        "https://github.com/libssh2/libssh2/releases/download/libssh2-$LIBSSH2_VERSION/libssh2-$LIBSSH2_VERSION.tar.gz" \
        "libssh2-$LIBSSH2_VERSION.tar.gz"
    cd "$BUILD" && rm -rf "libssh2-$LIBSSH2_VERSION" && tar xf "libssh2-$LIBSSH2_VERSION.tar.gz"
    cd "$BUILD/libssh2-$LIBSSH2_VERSION"
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF \
        -DOPENSSL_ROOT_DIR="$BUILD/openssl-$OPENSSL_VERSION" \
        -DOPENSSL_INCLUDE_DIR="$BUILD/openssl-$OPENSSL_VERSION/include" \
        -DOPENSSL_CRYPTO_LIBRARY="$EXT/openssl/lib/Linux/libcrypto.a" \
        -DOPENSSL_SSL_LIBRARY="$EXT/openssl/lib/Linux/libssl.a" \
        -DZLIB_LIBRARY="$EXT/zlib/lib/Linux/libz.a" \
        -DZLIB_INCLUDE_DIR="$BUILD/zlib-$ZLIB_VERSION"
    cmake --build build --parallel "$JOBS"
    cp build/src/libssh2.a "$EXT/libssh2/lib/Linux/"
    echo "libssh2 done"
}

# --- libgit2 ---
build_libgit2() {
    echo "======= Building libgit2 ======="
    download_if_missing \
        "https://github.com/libgit2/libgit2/archive/refs/tags/v$LIBGIT2_VERSION.tar.gz" \
        "libgit2-$LIBGIT2_VERSION.tar.gz"
    cd "$BUILD" && rm -rf "libgit2-$LIBGIT2_VERSION" && tar xf "libgit2-$LIBGIT2_VERSION.tar.gz"
    cd "$BUILD/libgit2-$LIBGIT2_VERSION"
    # REGEX_BACKEND=builtin: do not depend on the system libpcre (libpcre3 is gone
    # from Debian 13 / Ubuntu 25.04+).
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTS=OFF -DBUILD_CLI=OFF \
        -DUSE_SSH=libssh2 \
        -DUSE_HTTPS=OpenSSL \
        -DREGEX_BACKEND=builtin \
        -DUSE_GSSAPI=OFF \
        -DLIBSSH2_INCLUDE_DIR="$BUILD/libssh2-$LIBSSH2_VERSION/include" \
        -DLIBSSH2_LIBRARY="$EXT/libssh2/lib/Linux/libssh2.a" \
        -DOPENSSL_ROOT_DIR="$BUILD/openssl-$OPENSSL_VERSION" \
        -DOPENSSL_INCLUDE_DIR="$BUILD/openssl-$OPENSSL_VERSION/include" \
        -DOPENSSL_CRYPTO_LIBRARY="$EXT/openssl/lib/Linux/libcrypto.a" \
        -DOPENSSL_SSL_LIBRARY="$EXT/openssl/lib/Linux/libssl.a" \
        -DZLIB_LIBRARY="$EXT/zlib/lib/Linux/libz.a" \
        -DZLIB_INCLUDE_DIR="$BUILD/zlib-$ZLIB_VERSION" \
        -DPKG_CONFIG_EXECUTABLE=/dev/null
    cmake --build build --parallel "$JOBS"
    cp build/libgit2.a "$EXT/libgit2/lib/Linux/"
    echo "libgit2 done"
}

# --- libarchive ---
build_libarchive() {
    echo "======= Building libarchive ======="
    download_if_missing \
        "https://github.com/libarchive/libarchive/releases/download/v$LIBARCHIVE_VERSION/libarchive-$LIBARCHIVE_VERSION.tar.gz" \
        "libarchive-$LIBARCHIVE_VERSION.tar.gz"
    cd "$BUILD" && rm -rf "libarchive-$LIBARCHIVE_VERSION" && tar xf "libarchive-$LIBARCHIVE_VERSION.tar.gz"
    cd "$BUILD/libarchive-$LIBARCHIVE_VERSION"
    # Only zlib/bzip2/xz at runtime (stable sonames on every distro). libxml2 is off:
    # its soname changes (libxml2.so.2 -> .so.16 on Ubuntu 26.04) and it only adds XAR.
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_TEST=OFF \
        -DENABLE_TAR=OFF -DENABLE_CPIO=OFF -DENABLE_CAT=OFF -DENABLE_UNZIP=OFF \
        -DENABLE_LZ4=OFF -DENABLE_ZSTD=OFF -DENABLE_LZO=OFF \
        -DENABLE_OPENSSL=OFF -DENABLE_NETTLE=OFF -DENABLE_MBEDTLS=OFF \
        -DENABLE_EXPAT=OFF -DENABLE_LIBXML2=OFF \
        -DENABLE_ACL=OFF -DENABLE_XATTR=OFF -DENABLE_LIBB2=OFF -DENABLE_ICONV=OFF \
        -DZLIB_LIBRARY="$EXT/zlib/lib/Linux/libz.a" \
        -DZLIB_INCLUDE_DIR="$BUILD/zlib-$ZLIB_VERSION"
    cmake --build build --parallel "$JOBS"
    cp build/libarchive/libarchive.a "$EXT/libarchive/lib/Linux/"
    echo "libarchive done"
}

run_step zlib "${ZLIB_VERSION}"
run_step openssl "${OPENSSL_VERSION}"
run_step libssh2 "${LIBSSH2_VERSION}"
run_step libgit2 "${LIBGIT2_VERSION}"
run_step libarchive "${LIBARCHIVE_VERSION}"

echo ""
echo "======= All done! ======="
newest=$(cat "$EXT"/*/lib/Linux/*.a | grep -aoE '__isoc23_[a-z]+' | head -1 || true)
if [ -n "$newest" ]; then
    echo "WARNING: the libraries reference $newest (glibc 2.38+)."
fi
echo "Static libraries rebuilt against glibc $(getconf GNU_LIBC_VERSION | awk '{ print $2 }')"
