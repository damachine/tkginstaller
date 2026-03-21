## Linux+Nvidia ─ Combined Kernel & Driver Installation

---

**Installs Linux-TKG followed by Nvidia-all in a single run — both from the damachine staging fork.**

---

### Key Information:

- **Two-Step Install:** First builds and installs the Linux-TKG custom kernel, then automatically installs the matching Nvidia-all driver package.
- **Source:** Uses the `damachine` staging fork for both repositories (`github.com/damachine/linux-tkg` and `github.com/damachine/nvidia-all`).
- **Preset Config:** The `nvidia-all customization.cfg` is written from an embedded preset — no external config file (`_EXT_CONFIG_PATH`) needed. Edit the preset values in TKG-Installer to match your setup.
- **Prerequisites:** Ensure your `linux-tkg.cfg` is configured before running (use `tkginstaller config linux`).
- **Post-Install:** A **reboot** is required after both packages are installed for the new kernel and Nvidia driver to load.

---

### Quick Commands

- **Install:**  
  `tkginstaller linux-nvidia` or `tkginstaller ln`

---

### Build Order

1. **Linux-TKG** — custom kernel build from `damachine/linux-tkg`
2. **nvidia-all** — Nvidia driver build from `damachine/nvidia-all` with preset config

> If the Linux-TKG build fails, the Nvidia-all installation is **skipped automatically**.

---

### Configuration

- **Linux-TKG Config:**  
  `~/.config/frogminer/linux-tkg.cfg`  
  Edit with: `tkginstaller config linux`
- **Nvidia-all Preset Config:**  
  Written automatically from an embedded Heredoc inside TKG-Installer.  
  No external `_EXT_CONFIG_PATH` is set — the preset values are applied directly.
- **Key nvidia-all options to check in the preset:**
  - `_driver_version` — driver version to build (e.g. `"latest"`)
  - `_dkms` — DKMS or static module
  - `_open_source_modules` — open-source kernel modules
  - `_target_kernel` — target kernel (e.g. `"linux-tkg"`)
  - `_blacklist_nouveau` — blacklist nouveau driver

---

### Troubleshooting

- **Build fails on kernel step:**  
  Check `linux-tkg.cfg` settings and available disk space. The Nvidia step will not run.
- **Nvidia driver does not match kernel:**  
  Make sure `_target_kernel` in the preset matches the installed kernel (`linux-tkg`).
- **Permissions:**  
  Do not run TKG-Installer as root. Use a regular user account.

---

### Tips

- Run `tkginstaller config linux` first to review your kernel config before starting.
- Enough free disk space is essential — both a kernel and Nvidia driver need significant space.
- Join the Frogging-Family community for support.

---

**🌐 Online Preview**

#### ***See full documentation at:***

#### [damachine/linux-tkg](https://github.com/damachine/linux-tkg/blob/master/README.md) | [damachine/nvidia-all](https://github.com/damachine/nvidia-all/blob/master/README.md)
