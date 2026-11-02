#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="${1:-/tmp/libcamera-port}"
build_dir="$source_dir/build-verified"
install_dir="${HOME}/.local/lib/dell-7320-camera-rgbir"
dropin_dir="${HOME}/.config/systemd/user/wireplumber.service.d"
dropin="$dropin_dir/90-dell-7320-rgbir.conf"
old_pipewire_dropin="${HOME}/.config/systemd/user/pipewire.service.d/90-dell-7320-rgbir.conf"

required=(
	"$build_dir/src/libcamera/libcamera.so.0.7.2"
	"$build_dir/src/libcamera/base/libcamera-base.so.0.7.2"
	"$build_dir/src/ipa/simple/ipa_soft_simple.so"
	"$build_dir/src/ipa/simple/ipa_soft_simple.so.sign"
	"$build_dir/src/libcamera/proxy/worker/soft_ipa_proxy"
	"$project_dir/libcamera-rgbir/ov5675.yaml"
)
for file in "${required[@]}"; do
	if [[ ! -f "$file" ]]; then
		echo "Missing required build file: $file" >&2
		echo "Run ./scripts/reinstall-rgbir.sh $source_dir first." >&2
		exit 1
	fi
done

if [[ -e "$dropin" ]] && ! rg -q 'LIBCAMERA_SIMPLE_TUNING_FILE=.*dell-7320-camera-rgbir/ov5675.yaml' "$dropin"; then
	echo "Refusing to overwrite an unrelated WirePlumber override: $dropin" >&2
	echo "Move it aside or back it up first, then rerun this installer." >&2
	exit 1
fi
if [[ ! -f /usr/lib64/spa-0.2/libcamera/libspa-libcamera.so ]]; then
	echo "PipeWire libcamera plugin not found at /usr/lib64/spa-0.2/libcamera/libspa-libcamera.so" >&2
	exit 1
fi

mkdir -p "$install_dir/libcamera/base" "$install_dir/ipa" "$install_dir/proxy/worker"
cp -a "$build_dir/src/libcamera/libcamera.so"* "$install_dir/libcamera/"
cp -a "$build_dir/src/libcamera/base/libcamera-base.so"* "$install_dir/libcamera/base/"
install -m 0755 "$build_dir/src/ipa/simple/ipa_soft_simple.so" "$install_dir/ipa/"
install -m 0644 "$build_dir/src/ipa/simple/ipa_soft_simple.so.sign" "$install_dir/ipa/"
install -m 0755 "$build_dir/src/libcamera/proxy/worker/soft_ipa_proxy" "$install_dir/proxy/worker/"
install -m 0644 "$project_dir/libcamera-rgbir/ov5675.yaml" "$install_dir/ov5675.yaml"

mkdir -p "$dropin_dir"
cat > "$dropin" <<EOF
[Service]
# Managed by dell-7320-camera/scripts/install-pipewire-rgbir.sh
Environment="LD_LIBRARY_PATH=$install_dir/libcamera/base:$install_dir/libcamera"
Environment="LIBCAMERA_IPA_MODULE_PATH=$install_dir/ipa"
Environment="LIBCAMERA_IPA_PROXY_PATH=$install_dir/proxy/worker"
Environment="LIBCAMERA_SIMPLE_TUNING_FILE=$install_dir/ov5675.yaml"
Environment="LIBCAMERA_RGBIR=1"
Environment="RGBIR_IRSUB=0"
Environment="RGBIR_ORDER=GRBG"
EOF

if [[ -f "$old_pipewire_dropin" ]] && rg -q 'LIBCAMERA_RGBIR=1' "$old_pipewire_dropin"; then
	rm "$old_pipewire_dropin"
	rmdir --ignore-fail-on-non-empty "$(dirname "$old_pipewire_dropin")" 2>/dev/null || true
fi
if [[ "${RGBIR_SKIP_SYSTEMD_RESTART:-0}" == "1" ]]; then
	echo "RGB-IR files and WirePlumber override installed. The user service will load them at the next login."
else
	systemctl --user daemon-reload
	systemctl --user restart wireplumber.service
	echo "RGB-IR libcamera is installed for the user's WirePlumber camera service."
fi
echo "Open Camera again. To undo: ./scripts/uninstall-pipewire-rgbir.sh"
