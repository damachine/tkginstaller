## AMD Graphics Drivers ─ Vulkan drivers for AMD GPUs

---

**Installs custom-built AMD GPU drivers from the Frogging-Family repositories: AMDGPU-PRO (Vulkan-only) or AMDVLK-OPT (open-source, built from source).**

---

### Key Information:

- **Audience:** This option is for users with AMD graphics cards (Arch-based distributions only).
- **AMDGPU-PRO:** Professional Vulkan-only driver for RDNA and newer GPUs.
- **AMDVLK-OPT:** Open-source standalone Vulkan driver, built from source for maximum customization.
- **Process:** The installer clones the repository, applies patches if needed, and builds the package according to your configuration.
- **Post-Install:** A system restart is often recommended to ensure the new drivers are loaded correctly.

---

### Quick Commands

**AMDGPU-PRO:**
- **Install:**  
  `tkginstaller amdgpu-pro` or `tkginstaller amd` then select AMDGPU-PRO
- **Edit Config:**  
  `tkginstaller amdgpu-pro config` or `tkginstaller amd c`

**AMDVLK-OPT:**
- **Install:**  
  `tkginstaller amdvlk` or `tkginstaller amd` then select AMDVLK-OPT
- **Edit Config:**  
  `tkginstaller amdvlk config` or `tkginstaller av c`

---

### Configuration

- **Config Location:**  
  - AMDGPU-PRO: `~/.config/frogminer/amdgpu-pro.cfg`
  - AMDVLK-OPT: `~/.config/frogminer/amdvlk-opt.cfg`
- **Missing Config:**  
  If the config file is missing, TKG-Installer will prompt you to download the latest version from Frogging-Family.
- **Manual Updates:**  
  AMD driver configuration options may change. Update your config regularly for new features and fixes.
- **Backup:**  
  Always back up your config before making changes.

---

### Troubleshooting

- **Permissions:**  
  Do not run TKG-Installer as root. Use a regular user account for security.
- **Build Errors:**  
  Check that all dependencies are installed (`base-devel`) and your config is valid.
- **Driver Not Loading:**  
  Run `vulkaninfo | grep -i driver` to verify driver installation.
- **GPU Compatibility:**  
  Ensure your AMD GPU architecture is supported (RDNA, GCN, or newer).

---

### Tips

- Ensure you have the necessary build dependencies: `base-devel` package group.
- AMDVLK-OPT compilation may take several minutes; ensure adequate disk space (~2GB).
- Check for compatibility with your specific GPU model and kernel version.
- Join the Frogging-Family community for troubleshooting and support.

---

**🌐 Online Preview**

#### ***See full documentation at:***

#### [Frogging-Family/amdgpu-pro-vulkan-only](https://github.com/Frogging-Family/amdgpu-pro-vulkan-only)

#### [Frogging-Family/amdvlk-opt](https://github.com/Frogging-Family/amdvlk-opt)
