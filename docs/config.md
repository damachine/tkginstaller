## TKG-Installer - Config menu

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
  - `tkginstaller config linux` or `tkginstaller c l`

---

### Supported Packages

You can manage configuration files for the following TKG packages:

- **Linux-TKG:** `linux` or `l`
- **Nvidia-TKG:** `nvidia` or `n`
- **Mesa-TKG:** `mesa` or `m`
- **Wine-TKG:** `wine` or `w`
- **Proton-TKG:** `proton` or `p`

Shortcuts are supported for all package names and config actions (`c` for config, `e` for edit).

---

### File Management

- **Missing Files:** If a configuration file does not exist in the default directory, the script will prompt you to download the latest version from the official repository.
- **Manual Updates:** Configuration files from Frogging-Family may change over time. It's a good practice to manually update them periodically to get the latest options and fixes.
- **Backup:** Before editing, consider backing up your current configuration files.

---

### Troubleshooting

- **Invalid or incomplete arguments:** If you provide an invalid or incomplete command, TKG-Installer will show usage instructions and examples.
- **Permissions:** Do not run TKG-Installer as root. Use a regular user account for security.

---

**🌐 See full documentation at:**

- [TKG-Installer](https://github.com/damachine/tkginstaller)
- [Frogging-Family](https://github.com/Frogging-Family/)
