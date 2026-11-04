#!/usr/bin/env bash
# Replace the exact-kernel kmod with the akmod in one rpm-ostree transaction.
set -euo pipefail
project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ "${1:-}" != '--confirm' ]]; then
    echo 'This replaces the exact-kernel camera RPM with an akmod and installs its build tools.' >&2
    echo 'It creates a pending rpm-ostree deployment; it does not reboot.' >&2
    echo 'Review docs/installation.md and rerun with --confirm and the akmod RPM path.' >&2
    exit 2
fi
shift
rpm_file=${1:-}
if [[ -z "$rpm_file" ]]; then
    rpm_file=$(compgen -G "$project_dir/build/rpm-akmod/akmod-dell-7320-camera-*.rpm" | sort -V | tail -1 || true)
fi
[[ -n "$rpm_file" ]] || { echo 'Build the akmod RPM first with scripts/package-akmod.sh.' >&2; exit 1; }
test -r "$rpm_file" || { echo "Missing RPM: $rpm_file" >&2; exit 1; }
name=$(rpm -qp --qf '%{NAME}' "$rpm_file")
[[ "$name" == akmod-dell-7320-camera ]] || { echo "Expected akmod-dell-7320-camera; got $name" >&2; exit 1; }
base_rpm=$(compgen -G "$project_dir/build/rpm-akmod/dell-7320-camera-kmod-*.rpm" | sort -V | tail -1 || true)
[[ -n "$base_rpm" ]] || { echo 'The companion dell-7320-camera-kmod RPM is missing; rebuild the packages.' >&2; exit 1; }
test -r "$base_rpm" || { echo "Missing RPM: $base_rpm" >&2; exit 1; }
kernel_release=$(uname -r)
kernel_devel=$(rpm -q --whatprovides kernel-devel-uname-r 2>/dev/null || true)
[[ "$kernel_devel" == "kernel-devel-$kernel_release" ]] || {
    echo "Missing kernel-devel for the running kernel $kernel_release; install its matching kernel-devel before switching." >&2
    exit 1
}
sudo rpm-ostree install \
    --uninstall=dell-7320-camera-kmods \
    "$base_rpm" "$rpm_file"
echo 'A pending deployment has been created. Inspect rpm-ostree status before rebooting.'
