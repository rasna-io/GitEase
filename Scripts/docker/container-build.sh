#!/bin/bash
# Runs inside the gitease-build image (see Scripts/docker-build.sh, which sets
# OUT_DIR, DIST_DIR and REBUILD_EXT and mounts the repo at /src). The image
# provides Qt in /opt/Qt/$QT_VERSION.

set -euo pipefail

src=/src
qt_root="/opt/Qt/$QT_VERSION"
glibc="$(getconf GNU_LIBC_VERSION | awk '{ print $2 }')"
ext="$OUT_DIR/Ext"

echo "Container glibc $glibc, Qt $QT_VERSION, output $OUT_DIR"
mkdir -p "$OUT_DIR" "$DIST_DIR"

if [ "${PLUGINS_ONLY:-0}" = "1" ]; then
    ls "$OUT_DIR"/release/*.deb >/dev/null 2>&1 ||
        { echo "ERROR: --plugins-only needs a previous full build in $OUT_DIR/release"; exit 1; }
    echo "Reusing $(ls "$OUT_DIR"/release/*.deb), building plugins only"
else
# ---------- Ext: static libs built against this container's glibc ----------
# The committed Ext/*/lib/Linux/*.a may come from a newer distro; a copy of Ext
# with rebuilt Linux libs is kept in $OUT_DIR/Ext and reused on the next run.
if [ "$REBUILD_EXT" = "1" ] || [ ! -f "$ext/.glibc-$glibc" ]; then
    # A copy left by an interrupted run is kept: rebuild_ext.sh skips the
    # libraries it already finished (stamps in ext-src). A fresh copy has the
    # committed .a files back, so its stamps have to go.
    if [ "$REBUILD_EXT" = "1" ] || [ ! -d "$ext" ]; then
        rm -rf "$ext"
        rm -f "$OUT_DIR"/ext-src/.done-*
        cp -r "$src/Ext" "$ext"
    fi
    EXT_BUILD_DIR="$OUT_DIR/ext-src" bash "$src/Scripts/rebuild_ext.sh" "$ext"
    touch "$ext/.glibc-$glibc"
else
    echo "Reusing Ext libraries in $ext (--rebuild-ext to rebuild)"
fi

# ---------- GitEase .deb ----------
BUILD_DIR="$OUT_DIR/release" THIRD_PARTY_DIR="$ext" \
    bash "$src/Scripts/build.sh" --qt "$QT_VERSION" --glibc "$glibc"
fi

# ---------- Sample plugins, same Qt ----------
QT_PATH="$qt_root" bash "$src/SamplePlugins/build-linux-plugins.sh"

# Every plugin must load into the Qt bundled with the .deb and run on this glibc.
echo " ======= [Verifying plugins] ======= "
qt_minor="$(echo "$QT_VERSION" | cut -d. -f1,2)"
bad=0
for so in "$src"/SamplePlugins/*/lib/*.so; do
    need_glibc=$(objdump -T "$so" | grep -oE 'GLIBC_[0-9.]+' | sed 's/GLIBC_//' | sort -V | tail -1)
    need_qt=$(objdump -T "$so" | grep -oE 'Qt_6\.[0-9]+' | sed 's/Qt_//' | sort -V | tail -1)
    printf '%-45s glibc %-5s Qt %s\n' "${so#$src/}" "$need_glibc" "$need_qt"
    if [ "$(printf '%s\n%s\n' "$need_glibc" "$glibc" | sort -V | tail -1)" != "$glibc" ] ||
       [ "$(printf '%s\n%s\n' "$need_qt" "$qt_minor" | sort -V | tail -1)" != "$qt_minor" ]; then
        echo "  ERROR: needs a newer glibc or Qt than the package ships"
        bad=1
    fi
done
[ $bad -eq 0 ] || exit 1

# ---------- Collect ----------
rm -f "$DIST_DIR"/*.deb "$DIST_DIR"/*.gep
cp "$OUT_DIR"/release/*.deb "$DIST_DIR"/
cp "$src"/SamplePlugins/*/*.gep "$DIST_DIR"/
echo
echo "Done. Packages in ${DIST_DIR#/src/}:"
ls -l "$DIST_DIR"
