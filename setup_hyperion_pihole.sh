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
# 3. Anpassung der Systemeinstellungen (Locale, Tastatur, WLAN-Land, SPI-Aktivierung)
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
    # 2.1 Locale setzen
    echo "🌐 Setze Locale auf de_DE.UTF-8..."
    if sed -i 's/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen; then
      locale-gen && update-locale LANG=de_DE.UTF-8
      echo "✅ Locale gesetzt."
    else
      echo "❌ Fehler beim Setzen der Locale."
    fi

    # 2.2 Tastaturlayout auf Deutsch setzen
    echo "⌨️ Setze Tastaturlayout auf Deutsch..."
    if sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="de"/' /etc/default/keyboard; then
      dpkg-reconfigure -f noninteractive keyboard-configuration
      echo "✅ Tastaturlayout gesetzt."
    else
      echo "❌ Fehler beim Setzen des Tastaturlayouts."
    fi

    # 2.3 WLAN-Land auf DE setzen
    echo "📶 Setze WLAN-Land auf DE..."
    if ! grep -q "^country=DE" /etc/wpa_supplicant/wpa_supplicant.conf; then
      echo "country=DE" >> /etc/wpa_supplicant/wpa_supplicant.conf && echo "✅ WLAN-Land gesetzt."
    else
      echo "ℹ️ WLAN-Land ist bereits auf DE konfiguriert."
    fi
    
    info "✅ SPI aktivieren & Overlay setzen..."
    raspi-config nonint do_spi 0 && echo "✅ SPI erfolgreich aktiviert." || echo "❌ Fehler bei der SPI-Aktivierung."
    
    CONFIG_TXT="/boot/firmware/config.txt"
    [[ -f "/boot/config.txt" ]] && CONFIG_TXT="/boot/config.txt"
    
    if [[ ! -f "$CONFIG_TXT" ]]; then
        echo "❌ Fehler: config.txt nicht gefunden."
        exit 1
    fi
    
    echo dtoverlay=spi1-3cs,bufsize=4096 >> "$CONFIG_TXT" && echo "✅ SPI-Overlay hinzugefügt." || echo "❌ Fehler beim Hinzufügen des SPI-Overlays."
    
    info "3️⃣ Installation notwendiger Tools..."
    apt-get install -y git curl wget && echo "✅ Tools erfolgreich installiert." || echo "❌ Fehler bei der Tools-Installation."
    
    info "4️⃣ Pi-hole wird installiert..."
    curl -sSL https://install.pi-hole.net | bash && echo "✅ Pi-hole erfolgreich installiert." || echo "❌ Fehler bei der Pi-hole-Installation."
    
    # Warten auf Benutzerbestätigung nach der manuellen Einrichtung
    echo "⏳ Bitte schließe die manuelle Einrichtung von Pi-hole ab."
    echo "➡️ Falls du Pi-hole im Webinterface konfigurieren möchtest, rufe es auf unter:"
    echo "   📌 http://pi.hole oder http://<IP-Adresse>/admin"
    echo "⚠️ WICHTIG: Stelle sicher, dass du die Einrichtung vollständig abgeschlossen hast, bevor du fortfährst!"
    echo ""
        
    # Sicherheitsabfrage: Benutzer muss "ja" eingeben
    while true; do
        read -p "🔹 Bist du sicher, dass du mit der Einrichtung fertig bist? (ja/nein): " confirm
        case "$confirm" in
            [Jj][Aa] ) 
                echo "✅ Manuelle Einrichtung abgeschlossen. Skript wird fortgesetzt..."
                break
                ;;
            [Nn][Ee][Ii][Nn] ) 
                echo "⏳ Kein Problem! Nimm dir die Zeit, die du brauchst. Drücke [Enter], wenn du bereit bist..."
                read -r
                ;;
            * ) 
                echo "❌ Ungültige Eingabe. Bitte antworte mit 'ja' oder 'nein'."
                ;;
        esac
    done
    
    info "5️⃣ Hyperion wird installiert..."
    apt-get update -y
    apt-get install -y wget gpg apt-transport-https lsb-release && echo "✅ Hyperion erfolgreich installiert." || echo "❌ Fehler bei der Hyperion-Installation."
    
    wget -qO- https://releases.hyperion-project.org/hyperion.pub.key | \
    gpg --dearmor -o /usr/share/keyrings/hyperion.pub.gpg
    
    echo "deb [signed-by=/usr/share/keyrings/hyperion.pub.gpg] https://apt.releases.hyperion-project.org/ $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hyperion.list
    
    apt-get update -y
    apt-get install -y hyperion && echo "✅ Hyperion erfolgreich installiert." || echo "❌ Fehler bei der Hyperion-Installation."
    systemctl enable --now hyperion@alexo.service && echo "✅ Hyperion-Dienst erfolgreich gestartet." || echo "❌ Fehler beim Starten des Hyperion-Dienstes."
    
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
