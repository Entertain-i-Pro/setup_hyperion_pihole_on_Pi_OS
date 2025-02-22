#!/bin/bash
################################################################################
# setup_hyperion_pihole.sh
#
# Dieses Skript richtet einen Raspberry Pi 5 ein, um Hyperion und Pi-hole zu
# installieren. Dabei werden folgende Schritte ausgeführt:
#
# 1. Prüfung auf root-Rechte
# 2. Systemaktualisierung & Grundpakete
# 3. Deutschland-Einstellungen (Locale, Tastatur, WLAN-Land)
# 4. SPI-Aktivierung & Overlay in /boot/firmware/config.txt (dtoverlay=spi1-3cs,bufsize=4096)
# 5. Installation von Hyperion
# 6. Installation von Pi-hole (interaktiv)
# 7. Benutzerabfrage für Neustart
#
# HINWEIS:
# - Bitte nur auf einem aktuellen Raspberry Pi OS ausführen (getestet auf Debian-basiert).
# - Pi-hole-Installation ist interaktiv (Auswahl DNS, IP-Einstellungen usw.).
################################################################################

# Script bricht bei Fehler ab und meldet diesen.
set -euo pipefail
trap 'echo "❌ ERROR: Skript abgebrochen." ; exit 1' ERR

# Log-Datei erstellen
exec > >(tee -i /var/log/setup_hyperion_pihole.log) 2>&1

# Prüft, ob Skript als root ausgeführt wird.
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Dieses Skript muss als root (oder mit sudo) ausgeführt werden!"
    exit 1
  fi
}

# Gibt Info-Meldungen aus.
info() {
  echo -e "\033[1;34m[INFO]\033[0m $*"
}

# Installiert ein Paket, falls nicht vorhanden.
install_if_missing() {
  local cmd="$1"
  local pkg="$2"
  if ! command -v "$cmd" &> /dev/null; then
    info "📦 Installiere Paket: $pkg ..."
    apt-get install -y "$pkg"
  fi
}

main() {
  check_root

  info "1️⃣ System wird aktualisiert..."
  apt-get update -y
  apt-get upgrade -y

  # Wichtige Tools installieren (z.B. curl, raspi-config)
  info "2️⃣ Prüfe/Installiere notwendige Tools..."
  install_if_missing "raspi-config" "raspi-config"
  install_if_missing "curl" "curl"

  info "3️⃣ System auf Deutschland einstellen..."
  raspi-config nonint do_change_locale de_DE.UTF-8
  raspi-config nonint do_configure_keyboard de-latin1-nodeadkeys
  raspi-config nonint do_wifi_country DE

  info "4️⃣ SPI aktivieren und Overlay setzen..."
  raspi-config nonint do_spi 0

  CONFIG_TXT="/boot/firmware/config.txt"
  [[ -f "/boot/config.txt" ]] && CONFIG_TXT="/boot/config.txt"

  if [[ ! -f "$CONFIG_TXT" ]]; then
    echo "❌ FEHLER: Konnte config.txt nicht finden."
    exit 1
  fi

  sed -i '/^dtoverlay=spi1-3cs/d' "$CONFIG_TXT"
  sed -i '/^dtparam=spi=/d' "$CONFIG_TXT"

  echo "dtparam=spi=on" >> "$CONFIG_TXT"
  echo "dtoverlay=spi1-3cs,bufsize=4096" >> "$CONFIG_TXT"

  info "5️⃣ Installation von Hyperion..."
  apt-get update -y
  apt-get install -y wget gpg apt-transport-https lsb-release

  wget -qO- https://releases.hyperion-project.org/hyperion.pub.key | \
    gpg --dearmor -o /usr/share/keyrings/hyperion.pub.gpg

  echo "deb [signed-by=/usr/share/keyrings/hyperion.pub.gpg] https://apt.releases.hyperion-project.org/ $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hyperion.list

  apt-get update -y
  apt-get install -y hyperion
  systemctl enable --now hyperion

  info "6️⃣ Installation von Pi-hole..."
  curl -sSL https://install.pi-hole.net | bash

  info "7️⃣ Neustart in 5 Sekunden..."
  sleep 5

  read -p "🔄 Möchtest du den Raspberry Pi jetzt neustarten? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
      reboot
  else
      info "Bitte starte den Raspberry Pi manuell neu, um alle Änderungen zu übernehmen."
  fi
}

main "$@"

