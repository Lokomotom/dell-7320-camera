#!/usr/bin/env bash
# Build the local camera modules; never installs or loads them.
set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
kernel_release=${KERNEL_RELEASE:-$(uname -r)}
kernel_src=${KERNEL_SRC:?Set KERNEL_SRC to a local Fedora-patched kernel source tree}
kernel_build=${KERNEL_BUILD:-/lib/modules/$kernel_release/build}
output_dir="$project_dir/build/$kernel_release"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/dell7320-build.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

for file in \
    drivers/platform/x86/intel/int3472/tps68470.c \
    drivers/platform/x86/intel/int3472/tps68470_board_data.c \
    drivers/platform/x86/intel/int3472/tps68470.h \
    drivers/media/i2c/ov5675.c \
    drivers/media/pci/intel/ipu-bridge.c; do
    test -r "$kernel_src/$file" || { echo "Missing source file: $kernel_src/$file" >&2; exit 1; }
done
test -r "$kernel_build/Module.symvers" || { echo "Missing kernel build symbols: $kernel_build/Module.symvers" >&2; exit 1; }

mkdir -p \
    "$work_dir/drivers/platform/x86/intel/int3472" \
    "$work_dir/drivers/media/i2c" \
    "$work_dir/drivers/media/pci/intel"
for file in \
    drivers/platform/x86/intel/int3472/tps68470.c \
    drivers/platform/x86/intel/int3472/tps68470_board_data.c \
    drivers/platform/x86/intel/int3472/tps68470.h \
    drivers/media/i2c/ov5675.c \
    drivers/media/pci/intel/ipu-bridge.c; do
    install -m 0644 -D "$kernel_src/$file" "$work_dir/$file"
done
for patch_file in "$project_dir"/patches/000[123]-*.patch; do
    git -C "$work_dir" apply "$patch_file"
done

int3472_dir="$work_dir/drivers/platform/x86/intel/int3472"
ov5675_dir="$work_dir/drivers/media/i2c"
bridge_dir="$work_dir/drivers/media/pci/intel"
printf 'obj-m += intel_skl_int3472_tps68470.o\nintel_skl_int3472_tps68470-y := tps68470.o tps68470_board_data.o\n' > "$int3472_dir/Makefile"
printf 'obj-m += ov5675.o\n' > "$ov5675_dir/Makefile"
printf 'obj-m += ipu-bridge.o\n' > "$bridge_dir/Makefile"

make -C "$kernel_build" M="$int3472_dir" modules
make -C "$kernel_build" M="$ov5675_dir" modules
make -C "$kernel_build" M="$bridge_dir" modules

mkdir -p "$output_dir"
install -m 0644 \
    "$int3472_dir/intel_skl_int3472_tps68470.ko" \
    "$ov5675_dir/ov5675.ko" \
    "$bridge_dir/ipu-bridge.ko" \
    "$output_dir/"
for module_file in "$output_dir"/*.ko; do
    module_vermagic=$(modinfo -F vermagic "$module_file")
    case "$module_vermagic" in
        "$kernel_release"\ *) ;;
        *) echo "vermagic mismatch in $module_file: $module_vermagic" >&2; exit 1 ;;
    esac
    printf '%s: %s\n' "$(basename "$module_file")" "$module_vermagic"
done
printf 'Built modules are in %s. Nothing was installed or loaded.\n' "$output_dir"
