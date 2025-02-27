#!/bin/bash

################################################################################
# Setup-Skript: Hyperion & Pi-hole auf Raspberry Pi OS
#
# Dieses Skript automatisiert die Installation und Konfiguration von:
# - Hyperion (Ambilight-Software)
# - Pi-hole (Werbeblocker)
#
# ℹ️ Hinweis: Das Skript wird als Root ausgeführt.
################################################################################

# 1. Prüfung auf Root-Rechte
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Fehler: Dieses Skript muss als Root ausgeführt werden. Bitte mit 'sudo' starten!"
  exit 1
else
  echo "✅ Root-Rechte erkannt."
fi

# 2. Systemaktualisierung & Installation wichtiger Pakete
echo "🔄 Aktualisiere das System und installiere erforderliche Pakete..."
apt update && apt upgrade -y || { echo "❌ Fehler bei der Systemaktualisierung!"; exit 1; }
apt install -y git curl wget || { echo "❌ Fehler: Notwendige Pakete konnten nicht installiert werden!"; exit 1; }
echo "✅ Systemaktualisierung und Paketinstallation abgeschlossen."

# 3. Anpassung der Systemeinstellungen

# 3.1 Locale setzen
echo "🌐 Setze Locale auf de_DE.UTF-8..."
if sed -i 's/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen; then
  locale-gen && update-locale LANG=de_DE.UTF-8
  echo "✅ Locale gesetzt."
else
  echo "❌ Fehler beim Setzen der Locale."
fi

# 3.2 Tastaturlayout auf Deutsch setzen
echo "⌨️ Setze Tastaturlayout auf Deutsch..."
if sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="de"/' /etc/default/keyboard; then
  dpkg-reconfigure -f noninteractive keyboard-configuration
  echo "✅ Tastaturlayout gesetzt."
else
  echo "❌ Fehler beim Setzen des Tastaturlayouts."
fi

# 3.3 WLAN-Land auf DE setzen
echo "📶 Setze WLAN-Land auf DE..."
if ! grep -q "^country=DE" /etc/wpa_supplicant/wpa_supplicant.conf; then
  echo "country=DE" >> /etc/wpa_supplicant/wpa_supplicant.conf && echo "✅ WLAN-Land gesetzt."
else
  echo "ℹ️ WLAN-Land ist bereits auf DE konfiguriert."
fi

# 3.4 SPI aktivieren
echo "⚡ Aktiviere SPI-Schnittstelle..."
CONFIG_TXT="/boot/config.txt"
if ! grep -q "^dtparam=spi=on" "$CONFIG_TXT"; then
  echo "dtparam=spi=on" >> "$CONFIG_TXT" && echo "✅ SPI aktiviert."
else
  echo "ℹ️ SPI ist bereits aktiviert."
fi

# 3.5 Overlay hinzufügen
echo "🖥️ Füge Overlay 'dtoverlay=spi1-3cs,bufsize=4096' hinzu..."
if ! grep -q "^dtoverlay=spi1-3cs,bufsize=4096" "$CONFIG_TXT"; then
  echo dtoverlay=spi1-3cs,bufsize=4096 >> "$CONFIG_TXT" && echo "✅ Overlay hinzugefügt."
else
  echo "ℹ️ Overlay ist bereits vorhanden."
fi

# 4. Installation von Hyperion
echo "📥 Installiere Hyperion..."
HYPERION_URL="https://github.com/hyperion-project/hyperion.ng/releases/download/2.0.0/hyperion-2.0.0-Linux-armv7l.deb"
if wget "$HYPERION_URL" -O /tmp/hyperion.deb; then
  dpkg -i /tmp/hyperion.deb || { echo "❌ Fehler bei der Hyperion-Installation!"; exit 1; }
  systemctl enable hyperion.service && systemctl start hyperion.service
  echo "✅ Hyperion installiert und gestartet."
else
  echo "❌ Fehler: Hyperion-Paket konnte nicht heruntergeladen werden!"
  exit 1
fi

# 5. Installation von Pi-hole
echo "📥 Installiere Pi-hole..."
if curl -sSL https://install.pi-hole.net | bash; then
  echo "✅ Pi-hole Installation abgeschlossen."
else
  echo "❌ Fehler bei der Pi-hole Installation!"
  exit 1
fi

# 6. Neustart-Abfrage
read -p "🔄 Möchten Sie das System jetzt neu starten? (j/n): " choice
case "$choice" in
  j|J )
    echo "⏳ System wird neu gestartet..."
    reboot
    ;;
  n|N )
    echo "ℹ️ Bitte denken Sie daran, das System später neu zu starten, damit alle Änderungen wirksam werden."
    ;;
  * )
    echo "❌ Ungültige Eingabe. Bitte starten Sie das System manuell neu."
    ;;
esac
