# Local kernel patches

These patches are locally prepared for Fedora kernel `7.2.7-200.fc44` and apply after Fedora's `patch-7.2-redhat.patch`. They implement only the front sensor path. They have not been installed or submitted upstream.

Patch 1 uses the later upstream mailing-list revision with the corrected GPIO 5/active-low mapping. The earlier revision's GPIO 3 and powerdown mapping were wrong and were excluded. The rail enable set and reset mapping are documented in `../docs/hardware.md`; individual rail-to-sensor pin mapping remains unresolved.

Patches 2 and 3 are intentionally local experiments. Upstream review objected to describing RGB-IR as Bayer and asked to wait for Common Raw Sensor Model support. They can permit sensor binding/capture, but Bayer-based color output is inaccurate.

The preparation was informed by public kernel mailing-list review, not by the prohibited GitHub project:

- [TPS68470 board data v2](https://lists.openwall.net/linux-kernel/2026/08/16/153)
- [OVTI5678 ACPI ID discussion](https://lists.openwall.net/linux-kernel/2026/08/16/147)
- [IPU bridge configuration](https://lists.openwall.net/linux-kernel/2026/08/09/111)
