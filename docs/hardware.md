# Hardware a ověřené údaje

## Lokálně ověřeno

- Model: Dell Latitude 7320 Detachable; DMI SKU `0A45`, board `0P00J4`.
- ACPI front sensor: `OVTI5678:00`, UID `0`, path `\_SB_.PC00.LNK0`.
- ACPI PMIC/control logic: `INT3472:07`, UID `6`, path `\_SB_.PC00.CLP0`.
- TPS68470 revize `0x21` podle kernel logu.
- Když board data chybí, ovladač vrací `-ENODEV`; kamera I²C client se nevytvoří kvůli závislosti `_DEP`.

## Údaje z upstream testování na 7320 Detachable

Ve veřejném linux-kernel patch review autor a druhý vlastník stejného modelu ověřili reset na TPS68470 GPIO 5, aktivní v nule; GPIO 3 nemělo účinek a powerdown pin není používán. Test byl opakován na druhém kusu. Také ověřili, že I²C odpoví pouze při zapnutých VSIO, AUX1 a AUX2 společně. Nelze z toho samostatně určit, který rail fyzicky napájí které vstupní označení senzoru.

Stejné review uvádí ACPI SSDB 2 data lanes a MCLK 19.2 MHz; OV5675-kompatibilní driver očekává chip ID `0x5675`. IPU bridge návrh používá 450MHz link frequency. To jsou upstream testovací údaje, nikoli přímé odečty z tohoto zařízení v této fázi.

## Neověřeno na tomto stroji

- ACPI `_CRS`, `_DEP` a raw SSDB/CLDB v tabulkách nebyly dekompilovány.
- GPIO 5 a rail enable nebyly na tomto zařízení fyzicky změřeny ani aktivovány vlastním modulem.
- I²C adresa/response senzoru, MCLK, media graph a capture nebyly ověřeny po patchi.
- Zadní OVTI8856 GPIO mapping zůstává mimo rozsah.

Patche tedy nejsou instalovány. Pokud se testují, musí jít nejprve o samostatný rollbackovatelný boot/deployment; neměnit GPIO naslepo.
