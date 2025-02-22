# Setup Hyperion & Pi-hole – README

## 📌 Überblick
Dieses Skript automatisiert die Einrichtung von **Hyperion** (Ambilight-Software) und **Pi-hole** (Adblocker) auf einem **Raspberry Pi 5**. 
Es aktualisiert das System, stellt die Sprache auf Deutsch, aktiviert SPI mit dem Overlay `dtoverlay=spi1-3cs,bufsize=4096` 
und installiert beide Dienste. Am Ende wird der Pi neu gestartet.

## 🔹 Funktionen des Skripts
- Automatisches System-Upgrade
- Aktivierung von SPI und Setzen des Overlays in `config.txt`
- Konfiguration auf Deutschland (Locale, Tastatur, WLAN-Land)
- Hyperion-Installation (GPG-Key & Repository einrichten)
- Pi-hole-Installation (interaktiv)
- Automatischer Neustart nach Abschluss

## 📥 Installation & Nutzung
1. Skript herunterladen

wget https://example.com/setup_hyperion_pihole.sh chmod +x setup_hyperion_pihole.sh

2. Skript ausführen

sudo ./setup_hyperion_pihole.sh

3. Interaktive Schritte bei Pi-hole  
Während der Installation werden Fragen zu Netzwerk und DNS gestellt.

Nach dem Neustart sollten **Hyperion** und **Pi-hole** fertig eingerichtet sein.

## 🛠 Fehlerbehebung & Debugging
- **Hyperion-Status prüfen**

sudo systemctl status hyperion journalctl -u hyperion

- **Pi-hole prüfen**

pihole status pihole -c

- **SPI-Overlay validieren**

cat /boot/firmware/config.txt | grep spi1-3cs

- **Netzwerkfehler überprüfen**

ping -c 4 8.8.8.8 ip a

- **Neuinstallation von Hyperion oder Pi-hole**

sudo apt-get remove hyperion pihole uninstall


> **Hinweis:** Falls Probleme auftreten, bitte relevante Logausgaben (Hyperion, Pi-hole) beifügen, damit eine genauere Analyse möglich ist.
