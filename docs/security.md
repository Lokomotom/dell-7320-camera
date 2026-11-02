# Bezpečnost a soukromí

V této práci nebyly vytvořeny služby, sockety, firewall pravidla, automatické aktualizace ani vzdálená správa. Kernelový RPM `dell-7320-camera-kmods-0.1-3` je nainstalován pro kernel `7.2.7-200.fc44.x86_64`. Vlastní RGB-IR libcamera build a tuning jsou pouze v `/tmp/libcamera-port`; systémová knihovna libcamera nebyla nahrazena. Testovací snímky vznikly jen na výslovný pokyn uživatele a zůstaly v `/tmp`.

Pro přesný kernel build jsem po souhlasu uživatele získal zdrojový SRPM přímo z oficiálního Fedora Koji a ověřil jeho RPM digesty. Soubor i extrahované zdroje jsou v `/tmp`, mimo doručovaný projekt. Uživatelem uvedený GitHub projekt byl prohlédnut read-only; jeho instalační skripty ani RGB-IR implementace nebyly převzaty. Do lokálního tuning souboru byly vloženy zkontrolované CCM číselné hodnoty pro tento modul. Žádné diagnostické údaje, logy ani snímky nebyly odeslány.

Tím není auditována komunikace samotného Bluefinu ani jiných aplikací. Vlastní sestavené moduly neobsahují síťovou funkcionalitu. RGB-IR proměnné se nastavují pouze v lokálním capture helperu; nejsou přidány do globálního prostředí systému.
