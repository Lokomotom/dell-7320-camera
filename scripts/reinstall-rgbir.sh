#!/usr/bin/env bash
# Rebuild the isolated libcamera test build and refresh its tuning profile.
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="${1:-/tmp/libcamera-port}"
build_dir="$source_dir/build-verified"

if [[ ! -d "$build_dir" ]]; then
	echo "Missing configured build: $build_dir" >&2
	echo "Configure the libcamera 0.7.2 test build first; see docs/installation.md." >&2
	exit 1
fi

"$project_dir/scripts/patch-libcamera-rgbir.sh" "$source_dir"
env PATH="/tmp/dell7320-build-tools/bin:$PATH" \
	PYTHONPATH="/tmp/dell7320-build-tools" \
	meson configure "$build_dir" -Dbuildtype=release
env PATH="/tmp/dell7320-build-tools/bin:$PATH" \
	PYTHONPATH="/tmp/dell7320-build-tools" \
	ninja -C "$build_dir"

echo "Optimized local RGB-IR libcamera build refreshed. No system files or kernel modules were changed."
