#!/bin/bash
################################################################################

# Setup-Skript: Hyperion & Pi-hole auf Raspberry Pi 5
#
# Dieses Skript automatisiert die Installation und Konfiguration von:
# - Hyperion (Ambilight-Software)
# - Pi-hole (Adblocker)
#
# 📌 Ablauf des Skripts:
# 1. Prüfung auf root-Rechte
# 2. Systemaktualisierung & Installation wichtiger Pakete
# 3. Anpassung der Systemeinstellungen (Locale, Tastatur, WLAN-Land, SPI)
# 4. Installation von Hyperion & Aktivierung des Dienstes
# 5. Installation von Pi-hole (interaktiv)
# 6. Benutzerabfrage für Neustart
#
# ℹ️ Hinweise:
# - Das Skript ist für Raspberry Pi OS (Debian-basiert) optimiert.
# - Die Pi-hole-Installation ist interaktiv (z. B. DNS- & Netzwerk-Einstellungen).
################################################################################

# Fehlerbehandlung: Bei Fehlern abbrechen & Meldung ausgeben
set -euo pipefail
trap 'echo "❌ Fehler: Skript abgebrochen." ; exit 1' ERR

# Erstellung einer Log-Datei für das Setup
exec > >(tee -i /var/log/setup_hyperion_pihole.log) 2>&1

# 📌 Prüfen, ob Skript mit root-Rechten ausgeführt wird
check_root() {
if [[ $EUID -ne 0 ]]; then
    echo "❌ Dieses Skript muss als root (oder mit sudo) ausgeführt werden!"
    exit 1
fi
    echo "✅ Skript wird als Root ausgeführt."
}

# 📌 Funktion zur Anzeige von Info-Meldungen
info() {
    echo -e "\033[1;32m[INFO]\033[0m $*"
}

# --- Skriptablauf ---
main() {
    check_root
    
    info "1️⃣ System wird aktualisiert..."
    apt-get update -y && apt-get upgrade -y && echo "✅ Systemaktualisierung erfolgreich." || echo "❌ Fehler bei der Systemaktualisierung."
    
    info "2️⃣ Systemeinstellungen anpassen (Deutschland & SPI) ..."
    raspi-config nonint do_spi 0 && echo "✅ SPI erfolgreich aktiviert." || echo "❌ Fehler bei der SPI-Aktivierung."
    raspi-config nonint do_change_locale de_DE.UTF-8 && echo "✅ Locale gesetzt."
    export LANGUAGE=de_DE.UTF-8
    export LC_ALL=de_DE.UTF-8
    export LANG=de_DE.UTF-8
    locale-gen de_DE.UTF-8
    dpkg-reconfigure --frontend=noninteractive locales
    raspi-config nonint do_configure_keyboard de-latin1-nodeadkeys && echo "✅ Tastatur gesetzt."
    raspi-config nonint do_wifi_country DE && echo "✅ WLAN-Land gesetzt."
    sudo systemctl restart keyboard-setup
    sudo udevadm trigger --subsystem-match=input --action=change
    
    CONFIG_TXT="/boot/firmware/config.txt"
    [[ -f "/boot/config.txt" ]] && CONFIG_TXT="/boot/config.txt"
    
    if [[ ! -f "$CONFIG_TXT" ]]; then
        echo "❌ Fehler: config.txt nicht gefunden."
        exit 1
    fi
    
    if grep -q "\[ALL\]" "$CONFIG_TXT"; then
        echo "dtoverlay=spi1-3cs,bufsize=4096" >> "$CONFIG_TXT" && echo "✅ SPI-Overlay hinzugefügt." || echo "❌ Fehler beim Hinzufügen des SPI-Overlays."
    else
        echo "❌ Fehler: [ALL] Abschnitt nicht gefunden in config.txt."
        exit 1
    fi
    
    info "3️⃣ Installation notwendiger Tools..."
    apt-get install -y curl && echo "✅ Tools erfolgreich installiert." || echo "❌ Fehler bei der Tools-Installation."
    
    info "4️⃣ Pi-hole wird installiert..."
    curl -sSL https://install.pi-hole.net | bash && echo "✅ Pi-hole erfolgreich installiert." || echo "❌ Fehler bei der Pi-hole-Installation."
    
    info "5️⃣ Hyperion wird installiert..."
    apt-get update -y
    apt-get install -y wget gpg apt-transport-https lsb-release && echo "✅ Hyperion erfolgreich installiert." || echo "❌ Fehler bei der Hyperion-Installation."
    
    wget -qO- https://releases.hyperion-project.org/hyperion.pub.key | \
    gpg --dearmor -o /usr/share/keyrings/hyperion.pub.gpg
    
    echo "deb [signed-by=/usr/share/keyrings/hyperion.pub.gpg] https://apt.releases.hyperion-project.org/ $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hyperion.list
    
    apt-get update -y
    apt-get install -y hyperion && echo "✅ Hyperion erfolgreich installiert." || echo "❌ Fehler bei der Hyperion-Installation."
    systemctl enable --now hyperion && echo "✅ Hyperion-Dienst erfolgreich gestartet." || echo "❌ Fehler beim Starten des Hyperion-Dienstes."
    
    info "6️⃣ Neustart in 5 Sekunden..."
    sleep 5
    
    read -p "🔄 Möchtest du den Raspberry Pi jetzt neustarten? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    else
        info "Bitte starte den Raspberry Pi manuell neu, um alle Änderungen zu übernehmen."
    fi
}

# Skript ausführen
main "$@"
