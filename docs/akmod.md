# Akmod package

The original `dell-7320-camera-kmods` RPM contains compiled modules for exactly
one kernel. It pins `kernel-uname-r`, which can block a kernel update. The new
`dell-7320-camera-kmod` akmod carries source and builds kernel-specific modules
against the matching `kernel-devel` package through akmods.

The bundled source snapshot is based on Fedora kernel 7.2.11-200.fc44. The
Fedora `patch-7.2-redhat.patch` change to `ipu-bridge.c` was applied before the
three project patches. The original Fedora SRPM SHA-256 was
`5e7c2d81cd5fc54749e94917b6c2604c23c089dd0d277681e85e54d04bf6edc6`.
The project patches apply cleanly to that baseline. The bundled sources also
compiled into all three modules against the installed 7.2.7-200.fc44 kernel
headers. This does not certify every future kernel API; if a later kernel
changes one of these interfaces, the source snapshot will need an update.

## Build

Build dependencies are `rpmbuild`, `kmodtool`, GCC, make, and matching
`kernel-devel`.

```bash
./scripts/package-akmod.sh
```

The RPMs are written to `build/rpm-akmod/`. This only builds the packages; it
does not install them or change the running deployment.

## Replace the exact-kernel RPM

After reviewing the built akmod RPM, replace the old package in one
rpm-ostree transaction:

```bash
./scripts/install-akmod.sh --confirm
```

The script checks that matching `kernel-devel` for the running kernel is
already installed, requests `akmods` and `kmodtool`, removes
`dell-7320-camera-kmods`, and installs the akmod plus its companion package
containing the modules-load configuration in one transaction. Review
`rpm-ostree status`, then reboot into the pending deployment. The per-user
RGB-IR libcamera and WirePlumber setup is separate and is not changed by this
package conversion.

After each kernel update, akmods needs the matching `kernel-devel` package to
build the module for that kernel. A failed build means the new kernel should
not be booted with the camera expected to work; inspect `journalctl -u
akmods` and keep the prior deployment available for rollback.

If `rpm-ostree status` shows a versioned `kernel-devel` layer, replace it with
the exact `kernel-devel` build matching the kernel in the target deployment.
For the current target kernel 7.2.11, use:

```bash
sudo rpm-ostree upgrade \
  --uninstall=kernel-devel-7.2.7-200.fc44.x86_64 \
  --install=kernel-devel-7.2.11-200.fc44.x86_64
```

The plain `kernel-devel` request selected 7.2.15 while the Bluefin target
kernel was 7.2.11. In this deployment, `kernel-devel-matched` was reported as
already provided and did not supply the needed build tree, so select the exact
matching package. Update this version alongside any future target kernel bump.
