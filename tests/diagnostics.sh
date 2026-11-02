#!/usr/bin/env bash
# Read-only local diagnostics for Dell 7320 front camera. No network or mutation.
set -u

show() { printf '\n--- %s ---\n' "$1"; }

show 'Kernel and OS packages'
uname -r
rpm -q kernel kernel-core kernel-devel libcamera libcamera-tools 2>&1 || true
rpm-ostree status 2>&1 || true

show 'DMI identifiers'
for f in sys_vendor product_name product_sku board_name; do
    if [ -r "/sys/class/dmi/id/$f" ]; then
        printf '%s: %s\n' "$f" "$(cat "/sys/class/dmi/id/$f")"
    fi
done

show 'Relevant ACPI devices'
for id in INT3472 OVTI5678 OVTI5675 OVTI8856; do
    for d in /sys/bus/acpi/devices/"$id":*; do
        [ -e "$d" ] || continue
        printf '%s hid=%s uid=%s status=%s modalias=%s\n' \
            "$d" "$(cat "$d/hid" 2>/dev/null || true)" \
            "$(cat "$d/uid" 2>/dev/null || true)" \
            "$(cat "$d/status" 2>/dev/null || true)" \
            "$(cat "$d/modalias" 2>/dev/null || true)"
        printf '  driver=%s physical_node=%s\n' \
            "$(readlink -f "$d/driver" 2>/dev/null || true)" \
            "$(readlink -f "$d/physical_node" 2>/dev/null || true)"
    done
done

show 'Relevant module metadata'
for m in intel_skl_int3472_tps68470 ov5675 ipu_bridge; do
    printf '[%s]\n' "$m"
    modinfo -F filename "$m" 2>&1 || true
    modinfo -F alias "$m" 2>&1 || true
    modinfo -F vermagic "$m" 2>&1 || true
done

show 'Loaded camera-related modules'
lsmod | awk 'NR == 1 || tolower($1) ~ /(int3472|tps68470|ov5675|ov8856|ipu_bridge|intel_ipu6)/'

show 'Media device nodes'
ls -l /dev/media* /dev/video* 2>&1 || true

show 'Relevant current-boot kernel log'
journalctl -k -b --no-pager 2>&1 | grep -Ei 'int3472|ovti5678|ov5675|ipu.?bridge|tps68470|ov8856' | tail -100 || true
