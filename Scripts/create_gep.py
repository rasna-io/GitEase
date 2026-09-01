#!/usr/bin/env python3
"""create_gep.py — Build a GitEase Package (.gep) from a plugin directory.

GEP is a ZIP archive that ships only the files a plugin needs at runtime:
plugin.json (the descriptor), the cppEntry library folder (lib/), the qmlEntry
component folder (if any) and the icon. Sources and build artifacts (.cpp, .h,
CMakeLists.txt, …) are never packaged.

    <slug>-<version>.gep            (ZIP archive)
    ├── plugin.json                 (manifest + all metadata fields)
    └── lib/…                       (runtime DLL/SO, QML if not embedded)

The <slug> is a lowercase/hyphenated form of the plugin name, e.g.
"Repo Forest" -> "repo-forest". Run with `-h` for full usage.
"""

import argparse
import datetime
import json
import os
import re
import sys
import zipfile


def slugify(name: str) -> str:
    """Lowercase, collapse runs of non-alphanumerics into a single hyphen."""
    s = name.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s


def load_plugin_json(plugin_dir: str) -> dict:
    path = os.path.join(plugin_dir, "plugin.json")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def runtime_keep_prefixes(plugin_json: dict) -> list:
    """Relative paths (POSIX) that must ship in the package.

    Each entry is either a file or a directory prefix: the cppEntry library
    folder (e.g. "lib"), the qmlEntry component folder, and the icon.
    """
    keep = ["plugin.json"]
    for key in ("cppEntry", "qmlEntry", "icon"):
        value = plugin_json.get(key, "")
        if value:
            parent = os.path.dirname(value)
            keep.append(parent if parent else value)
    return keep


def is_kept(arc: str, keep_prefixes: list) -> bool:
    """True if arc (POSIX path) is one of the keep files or under one of the dirs."""
    for prefix in keep_prefixes:
        if arc == prefix or arc.startswith(prefix + "/"):
            return True
    return False


def total_size_bytes(src_dir: str, keep_prefixes: list) -> int:
    """Total size of the files that will actually ship in the package."""
    total = 0
    for root, _dirs, files in os.walk(src_dir):
        for name in files:
            if name.lower().endswith(".gep"):
                continue
            full = os.path.join(root, name)
            arc = os.path.relpath(full, src_dir).replace(os.sep, "/")
            if arc != "plugin.json" and not is_kept(arc, keep_prefixes):
                continue
            total += os.path.getsize(full)
    return total


def find_icon(plugin_dir: str) -> str:
    """Return the icon path relative to the plugin dir (using forward slashes), or ''."""
    candidates = [
        os.path.join("assets", "icon.png"),
        os.path.join("assets", "icon.jpg"),
        "icon.png",
        "icon.jpg",
        "icon.svg",
    ]
    for rel in candidates:
        if os.path.isfile(os.path.join(plugin_dir, rel)):
            return rel.replace(os.sep, "/")
    return ""


def build_manifest(plugin_json: dict, icon: str, size_bytes: int,
                   min_app_version: str) -> dict:
    """Augment the plugin manifest with all Models/Plugin metadata fields."""
    size_kb = max(1, round(size_bytes / 1024))
    manifest = dict(plugin_json)
    manifest["minAppVersion"] = min_app_version
    manifest["size"] = f"{size_kb} KB"
    manifest["releaseDate"] = datetime.date.today().isoformat()
    if icon:
        manifest["icon"] = icon
    if plugin_json.get("iconUrl"):
        manifest["iconUrl"] = plugin_json["iconUrl"]
    return manifest


def write_gep(src_dir: str, out_zip: str, keep_prefixes: list, manifest: dict) -> None:
    """Write the .gep archive: augmented plugin.json plus the kept runtime files.

    Entries are stored uncompressed (ZIP_STORED): plugin packages are mostly
    already-compressed binaries, and libarchive reads them back with no
    zlib/decompression dependency.
    """
    with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_STORED) as zf:
        zf.writestr("plugin.json",
                    json.dumps(manifest, indent=2, ensure_ascii=False))
        for root, _dirs, files in os.walk(src_dir):
            for name in files:
                full = os.path.join(root, name)
                arc = os.path.relpath(full, src_dir).replace(os.sep, "/")
                if arc == "plugin.json" or not is_kept(arc, keep_prefixes):
                    continue
                zf.write(full, arc)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="create_gep.py",
        description=(
            "Build a GitEase Package (.gep) from a plugin directory. "
            "The plugin's plugin.json doubles as the package descriptor."
        ),
        epilog=(
            "Examples:\n"
            "  python Scripts/create_gep.py SamplePlugins/repo-forest\n"
            "  python Scripts/create_gep.py SamplePlugins/repo-forest dist"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "plugin_dir",
        metavar="PLUGIN_DIR",
        help="Path to the plugin directory containing a plugin.json manifest.",
    )
    parser.add_argument(
        "output_dir",
        metavar="OUTPUT_DIR",
        nargs="?",
        default=None,
        help=(
            "Directory to write the .gep into. Defaults to PLUGIN_DIR itself "
            "(output inside each plugin folder)."
        ),
    )
    return parser


def main(argv=None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    plugin_dir = os.path.abspath(args.plugin_dir)
    output_dir = os.path.abspath(args.output_dir) if args.output_dir else plugin_dir

    if not os.path.isfile(os.path.join(plugin_dir, "plugin.json")):
        print(f"ERROR: no plugin.json found in {plugin_dir}", file=sys.stderr)
        return 1

    plugin_json = load_plugin_json(plugin_dir)
    name = plugin_json.get("name", "")
    version = plugin_json.get("version", "0.0.0")
    slug = slugify(name) or plugin_json.get("id", "plugin")

    if not name:
        print("ERROR: plugin.json is missing 'name'", file=sys.stderr)
        return 1

    icon = find_icon(plugin_dir)
    min_app_version = plugin_json.get("minAppVersion", "")

    # Only the runtime-required files ship in the package.
    keep = runtime_keep_prefixes(plugin_json)
    if icon:
        icon_dir = os.path.dirname(icon)
        keep.append(icon_dir if icon_dir else icon)

    size_bytes = total_size_bytes(plugin_dir, keep)
    manifest = build_manifest(plugin_json, icon, size_bytes, min_app_version)

    out_name = f"{slug}-{version}.gep"
    out_path = os.path.join(output_dir, out_name)

    os.makedirs(output_dir, exist_ok=True)
    write_gep(plugin_dir, out_path, keep, manifest)

    print(f"Created {out_path}")
    print(json.dumps(manifest, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())