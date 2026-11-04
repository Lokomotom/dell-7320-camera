#!/usr/bin/env bash
# Build the akmod RPM locally; does not install it or change the running system.
set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v rpmbuild >/dev/null || { echo 'rpmbuild is required.' >&2; exit 2; }
command -v kmodtool >/dev/null || { echo 'kmodtool is required (provided by the akmods packaging tools).' >&2; exit 2; }

mkdir -p "$project_dir/build/tmp"
real_topdir=$(mktemp -d "$project_dir/build/tmp/dell7320-akmod-rpm.XXXXXX")
topdir="/tmp/dell7320-akmod-rpm-$$"
ln -s "$real_topdir" "$topdir"
trap 'rm -f "$topdir"; rm -rf "$real_topdir"' EXIT
mkdir -p "$topdir"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS,tmp}

cp "$project_dir/packaging/dell-7320-camera-kmod-0.2.tar.xz" "$topdir/SOURCES/"
cp "$project_dir/packaging/dell-7320-camera-kmod-excludekernel-filterfile" "$topdir/SOURCES/"
cp "$project_dir/packaging/dell-7320-camera.conf" "$topdir/SOURCES/"
cp "$project_dir/packaging/dell-7320-camera-kmod.spec" "$topdir/SPECS/"
rpmbuild -ba --define "_topdir $topdir" --define "_tmppath $topdir/tmp" \
    "$topdir/SPECS/dell-7320-camera-kmod.spec"

mkdir -p "$project_dir/build/rpm-akmod"
cp "$topdir"/RPMS/*/*.rpm "$project_dir/build/rpm-akmod/"
cp "$topdir"/SRPMS/*.src.rpm "$project_dir/build/rpm-akmod/"
printf 'Akmod RPMs built in %s. They have not been installed.\n' "$project_dir/build/rpm-akmod"
