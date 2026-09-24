#!/bin/bash
set -e

EXT="$HOME/Projects/GitEase/Ext"
BUILD="/tmp/gitease-build"

# Skip already-downloaded tarballs
download_if_missing() {
    local url="$1"
    local file="$2"
    if [ -f "$BUILD/$file" ]; then
        echo "  (already downloaded: $file)"
    else
        wget "$url" -O "$BUILD/$file"
    fi
}

mkdir -p "$BUILD"

# --- zlib ---
echo "======= Building zlib ======="
download_if_missing \
    "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz" \
    "zlib-1.3.1.tar.gz"
cd "$BUILD" && tar xf zlib-1.3.1.tar.gz
cd "$BUILD/zlib-1.3.1"
./configure --static
make -j$(nproc)
cp libz.a "$EXT/zlib/lib/Linux/"
echo "zlib done"

# --- openssl ---
echo "======= Building openssl ======="
download_if_missing \
    "https://github.com/openssl/openssl/releases/download/openssl-3.0.15/openssl-3.0.15.tar.gz" \
    "openssl-3.0.15.tar.gz"
cd "$BUILD" && tar xf openssl-3.0.15.tar.gz
cd "$BUILD/openssl-3.0.15"
./Configure linux-x86_64 no-shared \
    --with-zlib-include="$BUILD/zlib-1.3.1" \
    --with-zlib-lib="$EXT/zlib/lib/Linux"
make -j$(nproc)
cp libssl.a libcrypto.a "$EXT/openssl/lib/Linux/"
echo "openssl done"

# --- libssh2 ---
echo "======= Building libssh2 ======="
download_if_missing \
    "https://github.com/libssh2/libssh2/releases/download/libssh2-1.11.1/libssh2-1.11.1.tar.gz" \
    "libssh2-1.11.1.tar.gz"
cd "$BUILD" && tar xf libssh2-1.11.1.tar.gz
cd "$BUILD/libssh2-1.11.1"
rm -rf build
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DOPENSSL_ROOT_DIR="$BUILD/openssl-3.0.15" \
    -DOPENSSL_CRYPTO_LIBRARY="$EXT/openssl/lib/Linux/libcrypto.a" \
    -DOPENSSL_SSL_LIBRARY="$EXT/openssl/lib/Linux/libssl.a" \
    -DZLIB_LIBRARY="$EXT/zlib/lib/Linux/libz.a" \
    -DZLIB_INCLUDE_DIR="$BUILD/zlib-1.3.1"
cmake --build build --parallel
cp build/src/libssh2.a "$EXT/libssh2/lib/Linux/"
echo "libssh2 done"

# --- libgit2 ---
echo "======= Building libgit2 ======="
download_if_missing \
    "https://github.com/libgit2/libgit2/archive/refs/tags/v1.8.4.tar.gz" \
    "libgit2-1.8.4.tar.gz"
cd "$BUILD" && tar xf libgit2-1.8.4.tar.gz
cd "$BUILD/libgit2-1.8.4"
rm -rf build
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DUSE_SSH=libssh2 \
    -DCMAKE_PREFIX_PATH="$BUILD/libssh2-1.11.1/build/src" \
    -DLIBSSH2_INCLUDE_DIR="$BUILD/libssh2-1.11.1/include" \
    -DLIBSSH2_LIBRARY="$BUILD/libssh2-1.11.1/build/src/libssh2.a" \
    -DOPENSSL_ROOT_DIR="$BUILD/openssl-3.0.15" \
    -DOPENSSL_CRYPTO_LIBRARY="$EXT/openssl/lib/Linux/libcrypto.a" \
    -DOPENSSL_SSL_LIBRARY="$EXT/openssl/lib/Linux/libssl.a" \
    -DZLIB_LIBRARY="$EXT/zlib/lib/Linux/libz.a" \
    -DZLIB_INCLUDE_DIR="$BUILD/zlib-1.3.1" \
    -DPKG_CONFIG_EXECUTABLE=/dev/null
cmake --build build --parallel
cp build/libgit2.a "$EXT/libgit2/lib/Linux/"
echo "libgit2 done"

echo ""
echo "======= All done! ======="
echo "All .a files rebuilt for Ubuntu 22 (glibc 2.35)"
