#!/usr/bin/env bash
# Repack the reviewed source snapshot into the akmod source archive.
set -euo pipefail
project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_dir="$project_dir/packaging/akmod-source/dell-7320-camera-kmod-0.2"
test -r "$source_dir/SOURCE-NOTES.md" || { echo 'Akmod source snapshot is missing.' >&2; exit 1; }
tar -cJf "$project_dir/packaging/dell-7320-camera-kmod-0.2.tar.xz" \
    -C "$project_dir/packaging/akmod-source" dell-7320-camera-kmod-0.2
printf 'Refreshed %s\n' "$project_dir/packaging/dell-7320-camera-kmod-0.2.tar.xz"
