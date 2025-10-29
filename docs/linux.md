## Linux-TKG ─ Custom Linux kernels

---

**Installs a custom-patched Linux kernel from the Frogging-Family, optimized for performance and gaming.**

---

### Key Information:

- **Dependencies:** Ensure you have the necessary build dependencies for compiling a kernel on your distribution (e.g., `base-devel` on Arch).
- **Process:** The installer clones the repository, builds the kernel using your external configuration, and installs it.
- **Build Time:** Compiling a kernel can take a significant amount of time, depending on your hardware.
- **Customization:** Allows for deep customization via the `linux-tkg.cfg` file. Use the configuration editor to tweak build options.
- **Post-Install:** After a successful installation, you must **reboot** your system to use the new kernel.

---

### Quick Commands

- **Install:**  
  `tkginstaller linux` or `tkginstaller l`
- **Edit Config:**  
  `tkginstaller linux config` or `tkginstaller l c`  
  `tkginstaller config linux` or `tkginstaller c l`

---

### Configuration

- **Config Location:**  
  Default: `~/.config/frogminer/linux-tkg.cfg`
- **Missing Config:**  
  If the config file is missing, TKG-Installer will prompt you to download the latest version from Frogging-Family.
- **Manual Updates:**  
  Kernel configuration options may change. Update your config regularly for new features and fixes.
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

- Ensure you have enough free disk space, as kernel sources are large.
- Join the Frogging-Family community for support and updates.
- Review the [Arch Wiki](https://wiki.archlinux.org/title/kernel) for general kernel build advice.

---

**🌐 Online Preview**

#### ***See full documentation at:***

#### [Frogging-Family/linux-tkg](https://github.com/Frogging-Family/linux-tkg/blob/master/README.md)
