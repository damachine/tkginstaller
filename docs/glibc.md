## glibc-eac — Easy Anti-Cheat compatible glibc

---

**Dieses Paket stellt eine EAC-kompatible glibc-Variante bereit (glibc-eac) und vereinfacht das Bauen/Installieren über das mitgelieferte Skript.**

---

### Key Information:

- **Purpose:** Modified glibc to improve compatibility mit Easy Anti-Cheat (EAC) bei bestimmten Spielen.
- **Repository:** Frogging-Family: `https://github.com/Frogging-Family/glibc-eac`
- **Build / Install:** Das Projekt stellt ein Skript `glibc_eac.sh` bereit. Laut upstream README:
  - `./glibc_eac.sh` → build & install
  - `./glibc_eac.sh build` → nur build (keine Installation)
- **No config file:** Es gibt keine `customization.cfg` für dieses Paket.

---

### Quick Commands

- **Install (build & install):**
  `tkginstaller glibc` oder `tkginstaller ge`
- **Build only:**
  `tkginstaller glibc` → auswählnummer: 2 (Only Build)

---

### Configuration

- **Config:** Keine lokale Konfigurationsdatei für glibc-eac vorhanden.

---

### Troubleshooting

- **Permissions:** Nicht als root ausführen.
- **Dependencies:** Stelle sicher, dass grundlegende Build-Tools (gcc, make, libc-devel, etc.) installiert sind.
- **Build errors:** Bei Fehlern schaue in das Ausgabeverzeichnis im Cache (`~/.tkginstaller/.cache/glibc`), bzw. in die Konsolenausgabe.

---

### Tips

- Verwende `./glibc_eac.sh build` zuerst, um sicherzustellen, dass der Build erfolgreich ist, bevor du installierst.
- Halte ein Backup deiner System-glibc (falls du lokal Installationen planst) und vergewissere dich, dass du ein funktionierendes Wiederherstellungs-szenario hast.

---

**🌐 Online Preview**

#### ***See upstream README at:***

#### [Frogging-Family/glibc-eac](https://github.com/Frogging-Family/glibc-eac/blob/main/README.md)
