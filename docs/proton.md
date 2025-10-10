## 🎮 Proton-TKG ─ Windows compatibility layer for Steam / Gaming

---

**Builds a custom Proton-TKG version from the Frogging-Family, allowing for fine-tuned performance and compatibility for Windows games on Linux via Steam.**

---

### Key Information:

- **Dependencies:** Requires a working Steam installation and numerous build dependencies for compiling Wine and other components.
- **Process:** The installer clones the `wine-tkg-git` repository, navigates to the `proton-tkg` directory, and executes the build script.
- **Build Time:** Compiling a full Proton environment is a lengthy process and can take a significant amount of time.
- **Customization:** Use the `proton-tkg.cfg` file to apply specific patches, change component versions, and tweak build options.
- **Post-Install:** The resulting Proton build will be placed in your Steam compatibility tools directory (`~/.steam/root/compatibilitytools.d/`). You must restart Steam to select and use it.

### Quick Commands:

- **Install:** `tkginstaller proton` or `tkginstaller p`
- **Edit Config:** `tkginstaller proton config` or `tkginstaller p c`

### Tips:

- Ensure you have a large amount of free disk space, as the build process is resource-intensive.
- Customizing can improve performance, but incorrect settings can also lead to issues.
- Join the Frogging-Family community for troubleshooting and support.

---

**🌐 Online Preview**

#### ***See full documentation at:***

#### [Frogging-Family/proton-tkg](https://github.com/Frogging-Family/proton-tkg/blob/master/README.md)
