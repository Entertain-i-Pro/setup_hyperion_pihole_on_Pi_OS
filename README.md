# Setup Hyperion & Pi-hole – README

## 📌 Überblick
Dieses Skript automatisiert die Einrichtung von **Hyperion** (Ambilight-Software) und **Pi-hole** (Adblocker) auf einem **Raspberry Pi 5**.
Das Skript sorgt für ein vollständiges System-Update, konfiguriert das System auf **deutsche Sprache & Tastatur**, aktiviert **SPI für Hyperion** und installiert beide Dienste. Nach Abschluss wird der Pi automatisch neu gestartet.

## 🔹 Funktionen des Skripts
- **Automatisches System-Upgrade & Bereinigung**
- **Aktivierung von SPI & Konfiguration des Overlays** (`dtoverlay=spi1-3cs,bufsize=4096`)
- **Regionaleinstellungen setzen** (Locale, Tastatur, WLAN-Land)
- **Installation von Hyperion** (GPG-Key & Repository hinzufügen)
- **Installation von Pi-hole** (interaktiver Modus für Netzwerkeinstellungen)
- **Automatischer Neustart nach erfolgreicher Einrichtung**

## 📥 Installation & Nutzung
### **1️⃣ Skript herunterladen & vorbereiten**
```bash
wget https://example.com/setup_hyperion_pihole.sh
chmod +x setup_hyperion_pihole.sh
```

### **2️⃣ Skript ausführen**
```bash
sudo ./setup_hyperion_pihole.sh
```
Während der Pi-hole-Installation werden interaktive Fragen zur Netzwerkkonfiguration und DNS-Serverwahl gestellt.

### **3️⃣ Neustart & Fertigstellung**
Nach dem automatischen Neustart sind **Hyperion & Pi-hole vollständig eingerichtet** und einsatzbereit.

## 🛠 Fehlerbehebung & Debugging
### **🔍 Hyperion-Status prüfen**
```bash
sudo systemctl status hyperion
journalctl -u hyperion
```

### **🔍 Pi-hole Status überprüfen**
```bash
pihole status
pihole -c
```

### **🔍 SPI-Overlay validieren**
```bash
cat /boot/firmware/config.txt | grep spi1-3cs
```

### **🔍 Netzwerkverbindung testen**
```bash
ping -c 4 8.8.8.8
ip a
```

### **🔄 Neuinstallation von Hyperion oder Pi-hole**
Falls Probleme auftreten, kann eine Neuinstallation helfen:
```bash
sudo apt-get remove --purge hyperion
pihole uninstall
```

⚠️ **Hinweis:** Falls weiterhin Probleme bestehen, bitte relevante Logausgaben (Hyperion & Pi-hole) bereitstellen, um eine genauere Analyse zu ermöglichen.

---

🚀 **Dein Raspberry Pi ist nun mit Hyperion & Pi-hole optimiert und bereit für den Einsatz!** 🎉
