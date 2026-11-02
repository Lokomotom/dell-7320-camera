# Instalace a reinstalace kamery na Bluefinu

## Stav této instalace

- Bluefin `44.20261029.1`, kernel `7.2.7-200.fc44.x86_64`.
- Kernelový RPM `dell-7320-camera-kmods-0.1-3.fc44.x86_64` je nainstalován; moduly se načítají při startu.
- Systémový libcamera je `0.7.2-2.fc44`.
- RGB-IR patche a barevný profil běží v izolovaném buildu `/tmp/libcamera-port`; systémová libcamera není nahrazena.

## Reinstalace barevného profilu

Toto je postup pro změny RGB-IR kódu nebo barevného nastavení. Kernelový RPM kvůli nim znovu instalovat není potřeba.

```bash
cd "/var/home/lokomotom/VS Code Projects/dell-7320-camera"
./scripts/reinstall-rgbir.sh /tmp/libcamera-port
./scripts/capture-rgbir.sh '/tmp/rgbir-final-#.ppm' 15
```

První skript idempotentně aplikuje patche 0004 (RGB-IR) a 0005 (AWB limit 8), nahraje zvolený `ov5675.yaml`, přepne build na optimalizovaný `release` režim a přeloží změněné cíle. Druhý použije GRBG, `RGBIR_IRSUB=0` a sytost 1.5; snímky uloží do `/tmp`.

Oba skripty jsou lokální: nepoužívají `sudo`, nemění kernelové moduly a neinstalují libcamera do systému. Build je nakonfigurovaný jen s pipeline `simple`; proto ho neinstaluj globálně přes `sudo ninja install`, jinak by systém přišel o ostatní pipeline.

## Reinstalace kernelových modulů

Kernelový balíček je samostatný. Jeho reinstalace nemění RGB-IR profil:

```bash
cd "/var/home/lokomotom/VS Code Projects/dell-7320-camera"
./scripts/install.sh --confirm build/rpm/dell-7320-camera-kmods-0.1-3.fc44.x86_64.rpm
rpm-ostree status
```

Po vytvoření nového deploymentu restartuj. Pokud balíček pouze aktualizuješ na stejný kernel, použij RPM sestavené pro výstup `uname -r`; RPM pro jiný kernel se nainstalovat nedá. Návrat je přes předchozí deployment nebo `rpm-ostree rollback`.

## Systémová a browser instalace

Lokální `cam` samo o sobě nemění aplikaci Fotoaparát. Pro její napojení lze nainstalovat upravené knihovny jen do uživatelského PipeWire procesu:

```bash
cd "/var/home/lokomotom/VS Code Projects/dell-7320-camera"
./scripts/install-pipewire-rgbir.sh /tmp/libcamera-port
```

Skript zkopíruje build do `~/.local/lib/dell-7320-camera-rgbir`, vytvoří uživatelský systemd override pro `wireplumber.service` (který v tomto systému načítá kamerový modul libcamera) a restartuje WirePlumber. Neinstaluje nic do systémových cest. Tento lokální build obsahuje pouze `simple` pipeline; ostatní kamery obsluhované stejným WirePlumberem mohou přestat být dostupné. Návrat proveď:

```bash
./scripts/uninstall-pipewire-rgbir.sh
```

Po integraci znovu otevři Snapshot. Pro ověření v terminálu můžeš hledat v logu WirePlumber řádek `Using tuning file .../.local/lib/dell-7320-camera-rgbir/ov5675.yaml`.
