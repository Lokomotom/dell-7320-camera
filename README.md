# Dell Latitude 7320 Detachable – přední kamera

Lokální projekt pro experimentální zpřístupnění přední OV5678 kamery přes standardní kernelové ovladače. Obsahuje patche, sestavené moduly, RPM a read-only diagnostiku. Kamera funguje v aplikaci Fotoaparát s lokálním RGB-IR zpracováním.

## Zjištěný stav zařízení

- Dell Latitude 7320 Detachable, SKU `0A45`, deska `0P00J4`.
- Kernel a kernel-devel: `7.2.7-200.fc44.x86_64`.
- libcamera/libcamera-tools: `0.7.2-2.fc44`.
- Kamera se v ACPI hlásí jako `OVTI5678:00`; její napájecí řadič je `INT3472:07`.
- Aktivní RPM `0.1-3` pro kernel `7.2.7-200.fc44.x86_64`; moduly byly úspěšně načteny a při startu se automaticky načítají.
- Kernel potvrzuje TPS68470 revizi `0x21`, dva připojené senzory a podporovaný `OVTI5678:00`.
- libcamera `cam -l` uvádí `Internal front camera`; jeden PPM snímek `2584×1944` byl úspěšně zachycen.

## Co je připraveno

- [Patch 1: TPS68470 board data](patches/0001-tps68470-dell-7320-board-data.patch) – přesné DMI match, INT3472:07, sedm větví TPS68470 a reset GPIO 5 aktivní v nule.
- [Patch 2: OV5675 ACPI ID](patches/0002-ov5675-add-ovti5678.patch).
- [Patch 3: IPU bridge sensor config](patches/0003-ipu-bridge-add-ovti5678.patch) – 1 CSI-2 link, 450 MHz.
- Zkompilované moduly pro přesný běžící kernel jsou v [build/7.2.7-200.fc44](build/7.2.7-200.fc44.x86_64/).
- [build.sh](scripts/build.sh) sestaví moduly z lokálního stromu zdrojů bez sítě a bez instalace. [package.sh](scripts/package.sh) připraví lokální RPM; revize `0.1-3` přidává boot-time načítání modulů a je nainstalovaná.
- [check-camera.sh](scripts/check-camera.sh) je read-only.
- [RGB-IR převod a lokální barevný profil](libcamera-rgbir/README.md) jsou ověřené na živém snímku. Vybraná fáze GRBG vykresluje červený a modrý předmět správně; profil používá Intel CCM a sytost 1.5. [Reinstall helper](scripts/reinstall-rgbir.sh) obnoví lokální build v `/tmp`; [capture helper](scripts/capture-rgbir.sh) vytvoří nové snímky. Ani jeden nic neinstaluje do systému.

## Aktuální stav aplikace Fotoaparát

Kamera nyní funguje přes uživatelský WirePlumber s lokálně optimalizovanou libcamera 0.7.2 a RGB-IR profilem. Knihovny a profil jsou v `~/.local/lib/dell-7320-camera-rgbir`; uživatelský override nastavuje GRBG, `RGBIR_IRSUB=0` a příslušný tuning. Systémová libcamera zůstává beze změny. Optimalizovaný build dosáhl přibližně 30 fps při přímém 1280×720 testovacím snímání; výsledné tempo v aplikaci Fotoaparát je přijatelné pro běžné použití.

Toto lokální napojení je dočasné, dokud podpora kamery nebude dostupná v oficiálním jádře a navazujícím systémovém stacku. Po přechodu na oficiální podporu lze uživatelský override a kopii knihoven odstranit příkazem `./scripts/uninstall-pipewire-rgbir.sh`.

## Důležitá omezení

OV5678 má RGB-IR 4×4 CFA, zatímco ovladač oznamuje běžný 2×2 Bayer. Lokální patch pro libcamera 0.7.2 převádí plné rozlišení RGB-IR na poloviční Bayer pro software ISP; záběry už ověřily správné pořadí barev a základní barevný profil. Jde stále o lokální testovací sestavení, ne o systémovou instalaci. Podrobnosti a limity jsou v [poznámkách k převodu](libcamera-rgbir/README.md).

Patch board data je založen na pozdější revizi upstream návrhu s GPIO 5; starší GPIO 3/powerdown variantu jsem nepoužil. Přesné přiřazení tří aktivních PMIC větví k `avdd`, `dvdd`, `dovdd` nebylo na hardwaru rozlišeno; návrh aktivuje VSIO/AUX1/AUX2, které byly společně nutné pro odpověď senzoru na I²C. Neznámé rear-camera GPIO nejsou zahrnuty.

Podrobnosti o Bluefin vrstvení a nasazení jsou v [instalačním plánu](docs/installation.md) a [návratu](docs/rollback.md). Podrobnosti jsou v [architektuře](docs/architecture.md), [hardwaru](docs/hardware.md) a [bezpečnosti](docs/security.md).


Soft ISP AWB patch [0005](patches/0005-libcamera-0.7.2-softisp-awb-gain.patch) zvyšuje limit zisku z 4 na 8. Několik prvních snímků může být zelenějších, než se automatika ustálí. V interiéru je patrný šum; zvolená sytost 1.5 je kompromis mezi živostí barev a barevným zrnem.
