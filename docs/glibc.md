## glibc-eac — Easy Anti-Cheat compatible glibc

---

**This package provides a glibc variant compatible with Easy Anti-Cheat (glibc-eac) and simplifies building/installing via the included script.**

---

### Key Information

- **Purpose:** A modified glibc intended to improve compatibility with Easy Anti-Cheat (EAC) for certain games.
- **Repository:** Frogging-Family: `https://github.com/Frogging-Family/glibc-eac`
- **Build / Install:** The project provides a script `glibc_eac.sh`. According to the upstream README:
  - `./glibc_eac.sh` → build & install
  - `./glibc_eac.sh build` → build only (no install)
- **No config file:** There is no `customization.cfg` for this package.

---

### Quick Commands

- **Install (build & install):**
  `tkginstaller glibc` or `tkginstaller ge`
- **Build only:**
  Run `tkginstaller glibc` and choose option **2** (Build only).

---

### Configuration

- **Config:** There is no local configuration file for glibc-eac.

---

### Troubleshooting

- **Permissions:** Do not run the installer as root.
- **Dependencies:** Ensure basic build tools are installed (gcc, make, libc-devel, etc.).
- **Build errors:** Check the output in the cache directory (`~/.tkginstaller/.cache/glibc`) or review console output for details.

---

### Tips

- Use `./glibc_eac.sh build` first to verify the build succeeds before installing.
- Keep a backup of your system glibc if you plan to perform local installations and ensure you have a recovery plan.

---

**🌐 Online Preview**

#### See upstream README at:

#### [Frogging-Family/glibc-eac](https://github.com/Frogging-Family/glibc-eac/blob/main/README.md)
