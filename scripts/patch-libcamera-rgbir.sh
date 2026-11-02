#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 || ! -d "$1" ]]; then
	echo "Usage: $0 /path/to/libcamera-0.7.2-source" >&2
	exit 2
fi

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$(cd "$1" && pwd)"
version="$(sed -n "s/^[[:space:]]*version[[:space:]]*:[[:space:]]*'\([0-9.]*\)'.*/\1/p" "$source_dir/meson.build" | head -n 1)"
if [[ "$version" != "0.7.2" ]]; then
	echo "Expected libcamera 0.7.2, found ${version:-unknown}; no changes made." >&2
	exit 1
fi

isp_dir="$source_dir/src/libcamera/software_isp"
rgbir_patch="$project_dir/patches/0004-libcamera-0.7.2-rgbir.patch"
awb_patch="$project_dir/patches/0005-libcamera-0.7.2-softisp-awb-gain.patch"

rgbir_applied=0
awb_applied=0
if patch -s -p1 -R --dry-run -d "$source_dir" < "$rgbir_patch" >/dev/null 2>&1; then
	rgbir_applied=1
fi
if patch -s -p1 -R --dry-run -d "$source_dir" < "$awb_patch" >/dev/null 2>&1; then
	awb_applied=1
fi

if (( rgbir_applied )); then
	cmp -s "$project_dir/libcamera-rgbir/rgbir_to_bayer.h" "$isp_dir/rgbir_to_bayer.h" || {
		echo "RGB-IR patch is present but its converter header differs." >&2
		exit 1
	}
	cmp -s "$project_dir/libcamera-rgbir/rgbir_to_bayer.cpp" "$isp_dir/rgbir_to_bayer.cpp" || {
		echo "RGB-IR patch is present but its converter source differs." >&2
		exit 1
	}
else
	patch -s -p1 --dry-run -d "$source_dir" < "$rgbir_patch" >/dev/null || {
		echo "RGB-IR patch does not apply cleanly; source tree left unchanged." >&2
		exit 1
	}
fi

if (( ! awb_applied )); then
	patch -s -p1 --dry-run -d "$source_dir" < "$awb_patch" >/dev/null || {
		echo "AWB patch does not apply cleanly; source tree left unchanged." >&2
		exit 1
	}
fi

if (( ! rgbir_applied )); then
	cp "$project_dir/libcamera-rgbir/rgbir_to_bayer.h" "$isp_dir/"
	cp "$project_dir/libcamera-rgbir/rgbir_to_bayer.cpp" "$isp_dir/"
	patch -s -p1 -d "$source_dir" < "$rgbir_patch"
fi
if (( ! awb_applied )); then
	patch -s -p1 -d "$source_dir" < "$awb_patch"
fi

install -m 0644 "$project_dir/libcamera-rgbir/ov5675.yaml" \
	"$source_dir/src/ipa/simple/data/ov5675.yaml"
echo "RGB-IR and AWB patches plus the selected tuning profile are ready in $source_dir. Nothing was installed system-wide."
