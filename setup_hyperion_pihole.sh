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
# 7. Neustart
#
# HINWEIS:
# - Bitte nur auf einem aktuellen Raspberry Pi OS ausführen (getestet auf Debian-basiert).
# - Pi-hole-Installation ist interaktiv (Auswahl DNS, IP-Einstellungen usw.).
################################################################################

# Script bricht bei Fehler ab und meldet diesen.
set -euo pipefail
trap 'echo "ERROR: Skript abgebrochen." ; exit 1' ERR

# --- FUNKTIONEN ---

# Prüft, ob Skript als root ausgeführt wird.
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Dieses Skript muss als root (oder mit sudo) ausgeführt werden!"
    exit 1
  fi
}

# Gibt Info-Meldungen in blau aus.
info() {
  echo -e "\033[1;34m[INFO]\033[0m $*"
}

# Installiert ein Paket, falls nicht vorhanden.
install_if_missing() {
  local cmd="$1"
  local pkg="$2"

  if ! command -v "$cmd" &> /dev/null; then
    info "Installiere Paket: $pkg ..."
    apt-get install -y "$pkg"
  fi
}

# --- HAUPTTEIL ---

main() {
  check_root

  info "1) System wird aktualisiert..."
  apt-get update -y
  apt-get upgrade -y

  # Wichtige Tools installieren (z.B. curl, raspi-config)
  info "2) Prüfe/Installiere notwendige Tools..."
  install_if_missing "raspi-config" "raspi-config"
  install_if_missing "curl" "curl"

  info "3) System auf Deutschland einstellen (Locale, Tastatur, WLAN-Land)..."
  # Locale
  raspi-config nonint do_change_locale de_DE.UTF-8
  # Tastatur (je nach Bedarf anpassbar)
  raspi-config nonint do_configure_keyboard de-latin1-nodeadkeys
  # WLAN-Land
  raspi-config nonint do_wifi_country DE

  info "4) SPI aktivieren und dtoverlay=spi1-3cs,bufsize=4096 setzen..."
  # SPI aktivieren
  raspi-config nonint do_spi 0

  # Pfad zur config.txt ermitteln (je nach OS-Version)
  CONFIG_TXT="/boot/firmware/config.txt"
  if [[ ! -f "$CONFIG_TXT" ]]; then
    CONFIG_TXT="/boot/config.txt"
  fi

  if [[ ! -f "$CONFIG_TXT" ]]; then
    echo "FEHLER: Konnte /boot/config.txt oder /boot/firmware/config.txt nicht finden."
    exit 1
  fi

  # Alte Einträge entfernen, um Duplikate zu vermeiden
  sed -i '/^dtoverlay=spi1-3cs/d' "$CONFIG_TXT"
  sed -i '/^dtparam=spi=/d' "$CONFIG_TXT"

  # Neue Einträge hinzufügen
  echo "dtparam=spi=on"                               >> "$CONFIG_TXT"
  echo "dtoverlay=spi1-3cs,bufsize=4096"             >> "$CONFIG_TXT"

  info "5) Installation von Hyperion..."
  apt-get update -y
  apt-get install -y wget gpg apt-transport-https lsb-release

  # GPG-Key hinzufügen
  wget -qO- https://releases.hyperion-project.org/hyperion.pub.key | \
    gpg --dearmor -o /usr/share/keyrings/hyperion.pub.gpg

  # APT-Quelle hinzufügen
  echo "deb [signed-by=/usr/share/keyrings/hyperion.pub.gpg] https://apt.releases.hyperion-project.org/ $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hyperion.list

  # Hyperion installieren
  apt-get update -y
  apt-get install -y hyperion

  info "6) Installation von Pi-hole (interaktiv)..."
  # Pi-hole Installation
  curl -sSL https://install.pi-hole.net | bash

  info "7) Neustart in 5 Sekunden..."
  sleep 5
  reboot
}

# --- Skriptstart ---
main "$@"
