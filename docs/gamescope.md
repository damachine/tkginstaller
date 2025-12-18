## Gamescope (gamescope-git) — Micro-compositor for gaming

---

**Plagman's micro-compositor formerly known as steamcompmgr. Useful for composing and benchmarking games, especially when working with Steam/Proton or performance testing.**

---

### Key Information:

- **Purpose:** A lightweight micro-compositor designed to present a game in a compositor with minimal overhead and optional Steam integration.
- **Repository:** The TKG package clones the Frogging-Family fork: `https://github.com/Frogging-Family/gamescope-git` which tracks Plagman's upstream work.
- **Build time:** Small and fast to build compared to Wine/Proton; still requires standard development toolchain and libwayland/mesa headers.
- **Customization:** A `customization.cfg` exists in the repository and can be edited via the TKG-Installer Config menu.

---

### Quick Commands

- **Install:**  
  `tkginstaller gamescope` or `tkginstaller g`
- **Edit Config:**  
  `tkginstaller gamescope config` or `tkginstaller g c`  
  `tkginstaller config gamescope` or `tkginstaller c g`

---

### Configuration

- **Config Location:**  
  Default: `~/.config/frogminer/gamescope.cfg`
- **Remote Config:**  
  Upstream: `gamescope-git/master/customization.cfg` (TKG-Installer will download it if missing)
- **Missing Config:**  
  If the config file is missing, TKG-Installer will prompt to download the default from Frogging-Family.

---

### Troubleshooting

- **Dependencies:** Ensure build dependencies are installed (compiler, meson/ninja or make depending on package, libwayland-dev, mesa headers, etc.).
- **Permissions:** Do not run TKG-Installer as root.
- **Build errors:** Check build logs in the cache directory (`~/.tkginstaller/.cache/gamescope`), ensure required dev packages are installed.

---

### Tips

- Gamescope is lightweight — use it for quick tests, benchmarking and capturing.  
- If you need Steam integration, consult the Plagman/Gamescope README for recommended launch options.  
- Keep the `customization.cfg` in `~/.config/frogminer/` backed up if you tweak advanced options.

---

**🌐 Online Preview**

#### ***See full documentation & upstream README at:***

#### [Frogging-Family/gamescope-git](https://github.com/Frogging-Family/gamescope-git/blob/master/README.md)
