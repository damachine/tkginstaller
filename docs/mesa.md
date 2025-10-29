## Mesa-TKG ─ Open-Source graphics driver for AMD and Intel

---

**Installs a custom-patched Mesa build from the Frogging-Family, providing the latest features and optimizations for AMD and Intel GPUs.**

---

### Key Information:

- **Audience:** This option is for users with AMD or Intel graphics cards.
- **Process:** The installer clones the `mesa-git` repository, applies TKG patches, and builds the package according to your configuration.
- **Customization:** Use the `mesa-git.cfg` file to enable or disable specific features and optimizations.
- **Post-Install:** A system restart is often recommended to ensure the new drivers are loaded correctly.

---

### Quick Commands

- **Install:**  
  `tkginstaller mesa` or `tkginstaller m`
- **Edit Config:**  
  `tkginstaller mesa config` or `tkginstaller m c`  
  `tkginstaller config mesa` or `tkginstaller c m`

---

### Configuration

- **Config Location:**  
  Default: `~/.config/frogminer/mesa-git.cfg`
- **Missing Config:**  
  If the config file is missing, TKG-Installer will prompt you to download the latest version from Frogging-Family.
- **Manual Updates:**  
  Mesa configuration options may change. Update your config regularly for new features and fixes.
- **Backup:**  
  Always back up your config before making changes.

---

### Troubleshooting

- **Invalid or incomplete arguments:**  
  If you provide an invalid or incomplete command, TKG-Installer will show usage instructions and examples.
- **Permissions:**  
  Do not run TKG-Installer as root. Use a regular user account for security.
- **Build Errors:**  
  Check that all dependencies are installed and your config is valid.

---

### Tips

- Ensure you have the necessary build dependencies for Mesa on your distribution.
- Check for compatibility with your specific GPU model and kernel version.
- Join the Frogging-Family community for troubleshooting and support.

---

**🌐 Online Preview**

#### ***See full documentation at:***

#### [Frogging-Family/mesa-tkg](https://github.com/Frogging-Family/mesa-tkg/blob/master/README.md)
