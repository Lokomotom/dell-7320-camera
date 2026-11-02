# Architektura a technická analýza

## Příčina původního selhání

Původní journal ukazoval `int3472-tps68470 i2c-INT3472:07: TPS68470 REVID: 0x21` následované `-ENODEV: No board-data found for this model`. ACPI `_DEP` na control logic zabraňuje vytvoření I²C klientů senzoru, dokud INT3472 neprojde probe. Board-data RPM 0.1-3 nyní umožňuje senzor rozpoznat a zachytit obraz.

## Komponenty

### INT3472 / TPS68470

Existující ovladač `intel_skl_int3472_tps68470` používá board data vyhledané přes DMI a jméno I²C zařízení. Patch přidává přesnou shodu `Dell Inc.` + `Latitude 7320 Detachable`, zařízení `i2c-INT3472:07`, lookup senzoru `i2c-OVTI5678:00` a reset na `tps68470-gpio` line 5, active-low. Nedefinuje powerdown, protože ov5675 ho nevyžaduje.

Board-data návrh deklaruje všech sedm railů TPS68470. VSIO/AUX1/AUX2 jsou připojené na spotřebitele senzoru pod jmény `avdd`/`dvdd`/`dovdd`; jejich jednotlivé fyzické funkce nebyly experimentálně odděleny. Core/ANA/VCM nemají spotřebitele v tomto patchi; upstream reviewer se výslovně ptal, zda jejich init data jsou nezbytná. Tuto nejistotu je třeba vyřešit při dalším review/testu.

### OV5675

OVTI5678 je přidáno do ACPI ID tabulky ov5675. Původní ovladač zůstává nezměněn: chip-ID očekává `0x5675`; ACPI SSDB hodnoty podle upstream měření odpovídají dvěma linkám a 19,2MHz MCLK. Změna neposkytuje samostatnou programovací tabulku pro nový senzor.

### IPU bridge

Přidán záznam `OVTI5678` s jednou link-frequency hodnotou 450MHz. Druhý argument makra `IPU_SENSOR_CONFIG` je počet frekvencí, nikoli počet CSI-2 linek; endpoint linky IPU bridge čte z ACPI SSDB. Upstream patch uvádí dvě data lanes. Lokální ACPI tabulka nebyla dekompilována, takže lane count ani fwnode graph zatím nebyly po patchi ověřeny na tomto kusu.

## RGB-IR a stav upstream

Senzor neposkytuje standardní Bayer 2×2 mozaiku; zveřejněná konfigurace konkrétního modulu popisuje 4×4 pattern a RGB-IR. Současný ovladač nemá odpovídající V4L2 media-bus kód. Maintainer linux-media upozornil, že deklarovat jej jako Bayer je nesprávné, a pozastavil ov5675/IPU-bridge změny do podpory Common Raw Sensor Model. Jeho odpověď na samostatný board-data patch také žádá zkrátit commit message a zpochybňuje nevyužité rail init data.

Lokální alias/bridge patche jsou cestou k surovému zachycení; upstream změny zůstávají experimentální kvůli chybějícímu RGB-IR formátu ve V4L2. Volitelný patch libcamera 0.7.2 převádí 4×4 RGB-IR mozaiku na poloviční Bayer před Software ISP. Na tomto kusu ovladač hlásí GRBG a záběr s červeným i modrým předmětem potvrdil GRBG jako správnou výstupní fázi. Tuning používá BlackLevel 4122, AWB limit 8 a sedm CCM pro OV5678; sytost 1.5 se nastavuje capture skriptem. Zrno zůstává viditelné v šeru; denoising nebyl zatím přidán.

## Build a kontroly

- Fedora SRPM odpovídající `kernel-core-7.2.7-200.fc44` byl ověřen RPM digestem a rozbalen do `/tmp`; aplikován byl Fedora patch `patch-7.2-redhat.patch`, který mění ipu-bridge baseline.
- Všechny tři patche prošly `git apply --check` proti čistému stromu s Fedora patchsetem.
- Všechny tři moduly se sestavily přes `/usr/src/kernels/7.2.7-200.fc44.x86_64`.
- `vermagic` všech modulů přesně odpovídá běžícímu kernelu.
- `ov5675.ko` obsahuje alias `acpi*:OVTI5678:*`; TPS68470 má očekávanou závislost na `intel_skl_int3472_common`.
- Build hlásil nesoulad verze `pahole` (kernel byl sestaven s 132, v prostředí 0) a vynechal BTF kvůli chybějícímu `vmlinux`; samotné moduly se úspěšně zlinkovaly.

RPM kernelových modulů 0.1-3 je aktuálně nainstalován a `cam -l` rozpoznává přední kameru. Zachycení plného RAW vstupu 2592×1944 a výstupu 1280×720 bylo ověřeno přes lokální libcamera build v `/tmp`. Tento build není nainstalován globálně; obsahuje pouze pipeline `simple`, proto jej nelze použít jako náhradu systémové knihovny pro všechny kamery.
