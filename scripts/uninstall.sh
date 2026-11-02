#!/usr/bin/env bash
# Remove the layered test package; reboot is required to select the new deployment.
set -euo pipefail
if [[ "${1:-}" != '--confirm' ]]; then
    echo 'This removes dell-7320-camera-kmods from the next deployment.' >&2
    echo 'Rerun with --confirm after reviewing docs/rollback.md.' >&2
    exit 2
fi
sudo rpm-ostree uninstall dell-7320-camera-kmods
echo 'A pending deployment has been created. Reboot to apply; rpm-ostree rollback is also available.'
