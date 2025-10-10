## 🛠️ TKG-Installer - Config menue

---

**Customize your TKG builds by editing the external configuration files from the Frogging-Family.**

- **Default Directory:** `~/.config/frogminer/`

---

### How to Edit Configuration Files

You can edit configuration files in two ways:

**1. Interactive Menu:**
- Select the `Config` option from the main menu.
- A new menu will appear, listing all available configuration files.
- The preview window shows the content of the selected file.

**2. Direct Command-Line:**
- Access configuration files directly without entering the menu.
- **Syntax:**
  - `tkginstaller [package] [config|c|edit|e]`
  - `tkginstaller [config|c|edit|e] [package]`
- **Examples:**
  - `tkginstaller linux config` or `tkginstaller l c`

---

### File Management

- **Missing Files:** If a configuration file does not exist in the default directory, the script will prompt you to download the latest version from the official repository.
- **Manual Updates:** Configuration files from Frogging-Family may change over time. It's a good practice to manually update them periodically to get the latest options and fixes.

---

**🌐 See full documentation at:**

- [TKG-Installer](https://github.com/damachine/tkginstaller)
- [Frogging-Family](https://github.com/Frogging-Family/)
