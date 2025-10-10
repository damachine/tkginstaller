### 🖥️ Nvidia-TKG ─ Open-Source or proprietary graphics driver

---

**Installs a custom-patched Nvidia driver from the Frogging-Family, offering support for both open-source and proprietary driver versions.**

---

### Key Information:

- **Driver Choice:** Supports both the open-source and proprietary Nvidia drivers. This can be configured in the `nvidia-all.cfg` file.
- **Process:** The installer clones the `nvidia-all` repository, applies TKG patches, and builds the driver package based on your configuration.
- **Customization:** Use the `nvidia-all.cfg` file to select the driver version, enable patches, and set other build options.
- **Post-Install:** A system **reboot** is required for the new driver to be loaded and take effect.

### Quick Commands:

- **Install:** `tkginstaller nvidia` or `tkginstaller n`
- **Edit Config:** `tkginstaller nvidia config` or `tkginstaller n c`

### Tips:

- Ensure you have the correct kernel headers installed for your running kernel.
- Check compatibility with your specific GPU model and the selected driver version.
- Join the Frogging-Family community for troubleshooting and support.

---

**🌐 Online Preview**

#### ***See full documentation at:***
#### [Frogging-Family/nvidia-all](https://github.com/Frogging-Family/nvidia-all/blob/master/README.md)
---
