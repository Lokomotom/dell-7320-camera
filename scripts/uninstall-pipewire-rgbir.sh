#!/usr/bin/env bash
set -euo pipefail

install_dir="${HOME}/.local/lib/dell-7320-camera-rgbir"
dropin="${HOME}/.config/systemd/user/wireplumber.service.d/90-dell-7320-rgbir.conf"

if [[ -f "$dropin" ]] && rg -q 'LIBCAMERA_RGBIR=1' "$dropin"; then
	rm "$dropin"
else
	echo "No managed Dell 7320 RGB-IR PipeWire override found; refusing to remove unrelated config." >&2
	exit 1
fi

rmdir --ignore-fail-on-non-empty "$(dirname "$dropin")" 2>/dev/null || true
rm -rf "$install_dir"
systemctl --user daemon-reload
systemctl --user restart wireplumber.service
echo "RGB-IR WirePlumber override removed; system libcamera is active again."
