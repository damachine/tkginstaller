
<p align="left">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  <img src="https://img.shields.io/badge/language-bash-blue?logo=gnu-bash">
  <a href="https://kernel.org/"><img src="https://img.shields.io/badge/Platform-Linux-green.svg"></a>
  <a href="https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21"></a>
  <a href="https://github.com/damachine/tkginstaller/issues"><img src="https://img.shields.io/github/issues/damachine/tkginstaller?&logo=github&label=Issues"></a>
  <a href="https://github.com/damachine/tkginstaller/discussions"><img src="https://img.shields.io/github/discussions/damachine/tkginstaller?&logo=github&label=Discussions"></a>
  <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a>
</p>

<pre style="font-family: 'Courier New', monospace; font-size: 132px; line-height: 1.2;">
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──
</pre>

This tool allows you to easy build, install, and customize system-specific TKG/Frogminer source packages
from the [Frogging-Family](https://github.com/Frogging-Family) repositories.

  * Use either an interactive `fzf` menu or a quick direct `terminal` command.
  * For maximum flexibility this tool allows you create, compare, and edit `customization.cfg` files.

**Installation**

- Arch Linux

   ```bash
   # STEP 1: Install
   yay -S tkginstaller-git
   #OR any other AUR helper

   # After installation, you can simply run:
   tkginstaller
   ```

- All Distributions *supported by the Frogging-Family*

   ```bash
   # STEP 1: Preparation
   mkdir -p /patch/to/tkginstaller
   cd /patch/to/tkginstaller

   # STEP 2: Download with curl
   curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller

   # STEP 3: Make script executable
   chmod +x tkginstaller
   ```
   ```bash
   # Optional: Make the installer available system-wide after manual installation

   # Method 1: Create a system link (Recommended)
   sudo ln -s /path/to/tkginstaller /usr/bin/tkginstaller

   # Method 2: Create a shell alias or function
   # Add one of this to your ~/.bashrc or ~/.zshrc:

   # As alias:
   alias tkginstaller='bash -c "/path/to/tkginstaller"'

   # OR as function:
   tkginstaller() {
      bash -c '/path/to/tkginstaller'
   }

   # Now you can run from anywhere:
   tkginstaller
   ```

**Usage**

- For a user-friendly, interactive, menu-driven experience, simply run:

   ```bash
   tkginstaller
   ```

- For quick, automated tasks, skips the interactive menu and use direct commands.

   ```bash
   # Syntax: tkginstaller [package]
   # Use full names or shortcuts (l, n, m, w, p)

   tkginstaller linux      # or 'tkginstaller l'
   tkginstaller nvidia     # or 'tkginstaller n'
   tkginstaller mesa       # or 'tkginstaller m'
   tkginstaller wine       # or 'tkginstaller w'
   tkginstaller proton     # or 'tkginstaller p'

   # Syntax: tkginstaller [package] [action]
   # Use full names or shortcuts (c, e for config/edit)

   # Edit a package's configuration file:
   tkginstaller linux config   # or 'tkginstaller l c'
   tkginstaller config linux   # or 'tkginstaller c l'
   tkginstaller mesa edit      # or 'tkginstaller m e'

   # Clean up all temporary files and restart installer:
   tkginstaller clean

   # Use 'help' or its shortcuts (h, --help, -h)
   tkginstaller help
   ```

---

📄 License

This installer script is released under the MIT License.

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

Individual TKG packages have their own licenses:
- See respective repositories at [https://github.com/Frogging-Family](https://github.com/Frogging-Family)

> *🙏 Your support keeps this project alive and improving — thank you!.*

---

👨‍💻 Developed by **DAMACHINE** 📧 Contact: christkue79@gmail.com 🌐 Repository: [GitHub](https://github.com/damachine/tkginstaller)
