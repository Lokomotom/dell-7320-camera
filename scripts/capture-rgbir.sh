#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="/tmp/libcamera-port/build-verified"
output_pattern="${1:-/tmp/rgbir-final-#.ppm}"
capture_count="${2:-15}"

if [[ ! "$capture_count" =~ ^[0-9]+$ ]] || (( capture_count < 1 )); then
	echo "Capture count must be a positive integer." >&2
	exit 2
fi

exec env \
	PATH="/tmp/dell7320-build-tools/bin:$PATH" \
	PYTHONPATH="/tmp/dell7320-build-tools" \
	LIBCAMERA_RGBIR=1 \
	RGBIR_IRSUB=0 \
	RGBIR_ORDER=GRBG \
	meson devenv -C "$build_dir" \
	/usr/bin/cam -c 1 --capture="$capture_count" \
	--file="$output_pattern" \
	--script "$project_dir/libcamera-rgbir/saturation-1_5.yaml" \
	-s role=viewfinder,width=1280,height=720
