#!/bin/bash
# Runs inside a clean distro image (see Scripts/docker-build.sh). Checks that
#   1. `apt-get install ./GitEase.deb` resolves every dependency by itself,
#   2. every ELF file in the package finds its libraries and glibc symbols,
#   3. GitEase starts (under Xvfb) and loads each sample plugin from /plugins.
# The last line is "RESULT ..." for the summary.

set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

. /etc/os-release
echo "== $PRETTY_NAME, glibc $(getconf GNU_LIBC_VERSION | awk '{ print $2 }')"

fail() { echo "RESULT $*"; exit 1; }

# ---------- 1. Install (apt resolves the Depends: line) ----------
# Debian releases past end of life (11 "bullseye" since Aug 2026) only live on
# archive.debian.org; the image still points at deb.debian.org, which answers 404.
if [ "$ID" = "debian" ] && [ "${VERSION_ID:-99}" -le 11 ]; then
    echo "Debian $VERSION_ID is end of life: using archive.debian.org"
    echo "deb http://archive.debian.org/debian $VERSION_CODENAME main" > /etc/apt/sources.list
    echo "deb http://archive.debian.org/debian-security $VERSION_CODENAME-security main" >> /etc/apt/sources.list
    rm -f /etc/apt/sources.list.d/*
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive
fi
apt-get update -qq >/dev/null || fail "apt-get update failed"
if ! apt-get install -y --no-install-recommends "$DEB" > /tmp/install.log 2>&1; then
    cat /tmp/install.log
    fail "install failed (unresolvable dependency, see log)"
fi
if dpkg -s gitease | grep -q '^Status: .*half'; then
    fail "package left half-configured"
fi
echo "installed: $(dpkg -s gitease | grep '^Version')"

# ---------- 2. Every ELF resolves ----------
missing=$(
    dpkg -L gitease | while read -r f; do
        [ -f "$f" ] && [ ! -L "$f" ] || continue
        [ "$(head -c4 "$f" | od -An -c | tr -d ' ')" = "177ELF" ] || continue
        ldd "$f" 2>&1 | grep -E 'not found' | sed "s|^|$f: |"
    done | sort -u
)
# Reported at the end, so the run still shows whether the app and plugins start.
missing_summary=""
if [ -n "$missing" ]; then
    echo "$missing"
    missing_summary="missing libraries: $(echo "$missing" | awk '/=> not found/ { print $(NF-3) }' | sort -u | tr '\n' ' ')"
else
    echo "all package libraries resolve"
fi

# ---------- 3. Start GitEase with the sample plugins ----------
apt-get install -y --no-install-recommends xvfb xauth > /dev/null 2>&1 || fail "could not install xvfb"

plugin_root="$HOME/.local/share/GitEase/plugins"
mkdir -p "$plugin_root"
expected=()
for dir in /plugins/*/; do
    [ -f "$dir/plugin.json" ] && ls "$dir"/lib/*.so >/dev/null 2>&1 || continue
    name=$(basename "$dir")
    mkdir -p "$plugin_root/$name/lib"
    cp "$dir/plugin.json" "$plugin_root/$name/"
    cp "$dir"/lib/*.so "$plugin_root/$name/lib/"
    [ -d "$dir/qml" ] && cp -r "$dir/qml" "$plugin_root/$name/"
    expected+=("$(grep -oE '"id" *: *"[^"]+"' "$dir/plugin.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')")
done

QT_QUICK_BACKEND=software QT_DEBUG_PLUGINS=0 \
    timeout 25 xvfb-run -a -s "-screen 0 1280x800x24" GitEase > /tmp/run.log 2>&1
code=$?
if [ $code -ne 124 ]; then
    tail -n 40 /tmp/run.log
    fail "GitEase exited early with code $code"
fi

grep -E 'Plugin (loaded|error)|Failed to load|incompatible' /tmp/run.log | sort -u
not_loaded=()
for id in "${expected[@]}"; do
    grep -q "Plugin loaded: $id" /tmp/run.log || not_loaded+=("$id")
done
if [ ${#not_loaded[@]} -gt 0 ]; then
    fail "runs, plugins not loaded: ${not_loaded[*]}${missing_summary:+; $missing_summary}"
fi
[ -z "$missing_summary" ] || fail "runs, ${#expected[@]} plugins loaded; $missing_summary"
echo "RESULT runs, ${#expected[@]}/${#expected[@]} plugins loaded"
