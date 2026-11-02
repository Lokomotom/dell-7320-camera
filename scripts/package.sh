#!/usr/bin/env bash
# Package already-built local modules. Does not install the resulting RPM.
set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
kernel_release=${KERNEL_RELEASE:-$(uname -r)}
build_dir="$project_dir/build/$kernel_release"
command -v rpmbuild >/dev/null || { echo 'rpmbuild is required; package build stopped without installing tools.' >&2; exit 2; }
for module_file in "$build_dir/intel_skl_int3472_tps68470.ko" "$build_dir/ov5675.ko" "$build_dir/ipu-bridge.ko"; do
    test -r "$module_file" || { echo "Missing built module: $module_file" >&2; exit 1; }
done

mkdir -p "$project_dir/build/tmp"
real_topdir=$(mktemp -d "$project_dir/build/tmp/dell7320-rpm.XXXXXX")
topdir="/tmp/dell7320-rpm-$$"
ln -s "$real_topdir" "$topdir"
trap 'rm -f "$topdir"; rm -rf "$real_topdir"' EXIT
mkdir -p "$topdir"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS,tmp}
cp "$build_dir/intel_skl_int3472_tps68470.ko" "$topdir/SOURCES/"
cp "$build_dir/ov5675.ko" "$topdir/SOURCES/"
cp "$build_dir/ipu-bridge.ko" "$topdir/SOURCES/"
cp "$project_dir/packaging/dell-7320-camera.conf" "$topdir/SOURCES/"
cp "$project_dir/packaging/dell-7320-camera-kmods.spec" "$topdir/SPECS/"
rpmbuild -bb --define "_topdir $topdir" --define "_tmppath $topdir/tmp" --define "kver $kernel_release" "$topdir/SPECS/dell-7320-camera-kmods.spec"
mkdir -p "$project_dir/build/rpm"
cp "$topdir"/RPMS/x86_64/*.rpm "$project_dir/build/rpm/"
printf 'RPM built locally in %s. It has not been installed.\n' "$project_dir/build/rpm"
