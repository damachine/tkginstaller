## TKG-Installer - Cleaning

---

**This option provides a safe way to remove all temporary files and reset the installer to a clean state.**

---

### What it does:

- **Removes Temporary Directory:** Deletes the entire `~/.cache/tkginstaller` directory. This includes:
  - Cloned Git repositories from previous builds.
  - Compiled packages and build artifacts.
  - Any other temporary files created by the installer.
- **Removes Lock File:** Deletes `/tmp/tkginstaller.lock` to prevent issues with restarting the installer.
- **Resets the Installer:** After cleaning, the script automatically restarts itself, ensuring a fresh session.
- **Displays a confirmation message:** You will see a message when cleaning is complete.

---

### When to use it:

- To free up disk space by removing old build files.
- To resolve potential issues caused by a stale or corrupted cache.
- To ensure a fresh clone of a repository for a new build.
- If you encounter problems starting the installer due to leftover lock files.

---

### Usage

- Select "Clean" from the main menu or use the corresponding command-line option.
- All temporary files and caches will be removed automatically.
- The installer will restart itself after cleaning.

---

### Tips

- Always use the "Clean" option before troubleshooting build or install issues.
- If cleaning does not resolve your issue, check for permission problems or manually remove the cache and lock files.

---

**🌐 See full documentation at:**

- [TKG-Installer](https://github.com/damachine/tkginstaller)
- [Frogging-Family](https://github.com/Frogging-Family/)
