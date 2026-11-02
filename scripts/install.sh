#!/usr/bin/env bash
# Layer the local RPM as a new Bluefin deployment. No reboot is performed here.
set -euo pipefail
project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ "${1:-}" != '--confirm' ]]; then
    echo 'This installs only kernel modules as a new rpm-ostree deployment.' >&2
    echo 'The RGB-IR libcamera build is separate; see docs/installation.md.' >&2
    echo 'Review docs/rollback.md and rerun with --confirm and the RPM path.' >&2
    exit 2
fi
shift
rpm_file=${1:-}
if [[ -z "$rpm_file" ]]; then
    rpm_file=$(compgen -G "$project_dir/build/rpm/dell-7320-camera-kmods-*.rpm" | sort -V | tail -1 || true)
fi
[[ -n "$rpm_file" ]] || { echo 'Build the local RPM first with scripts/package.sh.' >&2; exit 1; }
test -r "$rpm_file" || { echo "Missing RPM: $rpm_file" >&2; exit 1; }
expected=${KERNEL_RELEASE:-$(uname -r)}
actual=$(rpm -qp --requires "$rpm_file" | sed -n 's/^kernel-uname-r = //p' | head -1)
[[ "$actual" == "$expected" ]] || { echo "RPM kernel requirement $actual does not match running $expected" >&2; exit 1; }
if rpm -q dell-7320-camera-kmods >/dev/null 2>&1; then
    sudo rpm-ostree uninstall dell-7320-camera-kmods
fi
sudo rpm-ostree install --force-replacefiles "$rpm_file"
echo 'A pending deployment has been created. Inspect rpm-ostree status before rebooting.'
