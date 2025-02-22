README – Installation von Hyperion & Pi-hole
Download & Installation
Skript herunterladen

bash
Kopieren
wget https://example.com/setup_hyperion_pihole.sh
Ausführbar machen

bash
Kopieren
chmod +x setup_hyperion_pihole.sh
Skript starten

bash
Kopieren
sudo ./setup_hyperion_pihole.sh
Was macht das Skript?
System aktualisieren
Aktualisiert Paketquellen und führt Upgrade durch.

Sprache & Tastatur
Stellt das System auf Deutschland ein (Locale, Tastatur, WLAN-Land).

SPI aktivieren & Overlay
Aktiviert SPI und setzt dtoverlay=spi1-3cs,bufsize=4096 in config.txt.

Hyperion installieren
Lädt GPG-Key, richtet Repository ein und installiert Hyperion.

Pi-hole installieren
Führt das Standard-Installationsscript von Pi-hole aus (interaktiv).

Neustart
Startet den Raspberry Pi am Ende neu.

Mögliche Debug-Infos
Logdateien prüfen

journalctl -u hyperion.service
pihole -c (Statusübersicht Pi-hole)
Konfigurationsdateien

/boot/config.txt oder /boot/firmware/config.txt
/etc/hyperion/hyperion.config.json (Hyperion)
Netzwerkfehler

ping -c 4 8.8.8.8 (Internetverbindung testen)
ip a (Netzwerkschnittstellen prüfen)
Neuinstallation

Skript erneut ausführen oder manuell:
sudo apt-get remove hyperion
pihole uninstall
