### 🧹 TKG-Installer - Cleaning

---

**This option provides a safe way to remove all temporary files and reset the installer to a clean state.**

---

### What it does:

- **Removes Temporary Directory:** Deletes the entire `~/.cache/tkginstaller` directory. This includes:
  - Cloned Git repositories from previous builds.
  - Compiled packages and build artifacts.
  - Any other temporary files created by the installer.

- **Resets the Installer:** After cleaning, the script automatically restarts itself, ensuring a fresh session.

### When to use it:

- To free up disk space by removing old build files.
- To resolve potential issues caused by a stale or corrupted cache.
- To ensure a fresh clone of a repository for a new build.

---

**🌐 See full documentation at:**
- [TKG-Installer](https://github.com/damachine/tkginstaller)
- [Frogging-Family](https://github.com/Frogging-Family/)
