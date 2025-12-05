## Proton-TKG ─ Windows compatibility layer for Steam / Gaming

---

**Builds a custom Proton-TKG version from the Frogging-Family, allowing for fine-tuned performance and compatibility for Windows games on Linux via Steam.**

---

### Key Information:

- **Dependencies:** Requires a working Steam installation and numerous build dependencies for compiling Wine and other components.
- **Process:** The installer clones the `wine-tkg-git` repository, navigates to the `proton-tkg` directory, and executes the build script.
- **Build Time:** Compiling a full Proton environment is a lengthy process and can take a significant amount of time.
- **Customization:** Use the `proton-tkg.cfg` file to apply specific patches, change component versions, and tweak build options.
- **Post-Install:** The resulting Proton build will be placed in your Steam compatibility tools directory (`~/.steam/root/compatibilitytools.d/`). You must restart Steam to select and use it.

---

### Quick Commands

- **Install:**  
  `tkginstaller proton` or `tkginstaller p`
- **Edit Config:**  
  `tkginstaller proton config` or `tkginstaller p c`  
  `tkginstaller config proton` or `tkginstaller c p`

---

### Configuration

- **Config Location:**  
  Default: `~/.config/frogminer/proton-tkg.cfg`
- **Missing Config:**  
  If the config file is missing, TKG-Installer will prompt you to download the latest version from Frogging-Family.
- **Manual Updates:**  
  Proton configuration options may change. Update your config regularly for new features and fixes.
- **Backup:**  
  Always back up your config before making changes.

---

### DXVK-Tools Integration (Optional)

Before building Proton-TKG, you can optionally prepare custom DXVK and vkd3d-proton builds using dxvk-tools:

- **What is dxvk-tools?**  
  A build system for custom DXVK (DirectX to Vulkan) and vkd3d-proton (Direct3D 12 to Vulkan) versions.
- **When to use:**  
  Use this for cutting-edge DXVK/vkd3d versions, custom patches, or debugging purposes.
- **Workflow:**
  1. TKG-Installer asks: "Prepare custom DXVK/vkd3d with dxvk-tools first?"
  2. If yes → Clone dxvk-tools repository to `~/.tkginstaller/.cache/dxvk-tools`
  3. Ask: "Build DXVK?" → Runs `./updxvk build` if yes
  4. Ask: "Build vkd3d-proton?" → Runs `./upvkd3d-proton build` if yes
  5. Ask: "Export for Proton-TKG?" → Runs `./updxvk proton-tkg` if yes (only if something was built)
  6. Continue with Proton-TKG build using exported DLLs
- **Config Files:**  
  Edit `updxvk.cfg` and `upvkd3d-proton.cfg` via Config menu or:
  - `tkginstaller config dxvk`
  - `tkginstaller config vkd3d`
- **Standalone Installation:**  
  `tkginstaller dxvk-tools` or `tkginstaller dxvk`
- **Error Handling:**  
  If dxvk-tools build fails, Proton-TKG build continues anyway.
- **Requirements:**  
  wine, meson, mingw64, glslang (handled by dxvk-tools scripts).

---

### Troubleshooting

- **Invalid or incomplete arguments:**  
  If you provide an invalid or incomplete command, TKG-Installer will show usage instructions and examples.
- **Permissions:**  
  Do not run TKG-Installer as root. Use a regular user account for security.
- **Build Errors:**  
  Check that all dependencies are installed and your config is valid.
- **dxvk-tools Errors:**  
  Check logs in `~/.tkginstaller/.cache/` (dxvk-build.log, vkd3d-build.log, dxvk-export.log).

---

### Tips

- Ensure you have a large amount of free disk space, as the build process is resource-intensive.
- Customizing can improve performance, but incorrect settings can also lead to issues.
- Join the Frogging-Family community for troubleshooting and support.
- Use dxvk-tools only if you need bleeding-edge versions or custom patches.
- Default Proton-TKG already includes stable DXVK/vkd3d versions.

---

**🌐 Online Preview**

#### ***See full documentation at:***

#### [Frogging-Family/proton-tkg](https://github.com/Frogging-Family/proton-tkg/blob/master/README.md)
