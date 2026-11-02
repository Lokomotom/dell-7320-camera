# Nasazení a návrat

## Aktuální stav Bluefinu

Lokální kontrola zjistila Bluefin `44.20261029.1`, image `ostree-image-signed:docker://ghcr.io/ublue-os/bluefin:stable`, kernel `7.2.7-200.fc44.x86_64`, vrstvy `kernel-devel` a `rpm-build` a dostupný předchozí rollback deployment. Secure Boot je podle zadání vypnutý.

Aktuální initramfs neobsahuje moduly TPS68470, ov5675 ani ipu-bridge, proto plánovaný test nevyžaduje rebuild initramfs.

## Připravený způsob

Na Bluefinu je nainstalován lokální kmod RPM `dell-7320-camera-kmods-0.1-3.fc44.x86_64` pro přesný kernel `7.2.7-200.fc44.x86_64`. Balíček nahrazuje tři moduly a zajišťuje jejich načtení při startu. Reinstalaci nebo odebrání kernelového balíčku řídí `scripts/install.sh` a `scripts/uninstall.sh`; oba vyžadují `--confirm`.

RPM recept je v `packaging/`; `scripts/package.sh` jej sestaví. Barevný RGB-IR převod je oddělený: jeho zdroj a tuning jsou v `/tmp/libcamera-port` a nejsou instalovány do systému. Obnoví se příkazem `scripts/reinstall-rgbir.sh /tmp/libcamera-port`; tento build má pouze `simple` pipeline a nesmí se globálně instalovat přes systémovou libcamera.

## Návrat

- Než se pending deployment nabootuje: zrušit pending deployment podle `rpm-ostree status`/`rpm-ostree cleanup -p`.
- Po nabootování testovacího deploymentu: vybrat předchozí deployment v boot menu nebo použít `rpm-ostree rollback`, pak restartovat.
- Pro čisté odstranění kernelového balíčku: `sudo rpm-ostree uninstall dell-7320-camera-kmods` a restart.
- Uživatelský RGB-IR build nemění systém; pro návrat k systémové libcamera stačí přestat spouštět `scripts/capture-rgbir.sh`. Testovací build lze odstranit smazáním `/tmp/libcamera-port`.

Při aktualizaci na jiný kernel tento balíček nebude kompatibilní; musí se předem odstranit nebo znovu sestavit. Není připraven žádný automatický build ani aktualizace.
