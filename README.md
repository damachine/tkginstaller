
<pre style="font-family: 'Courier New', monospace; font-size: 32px; line-height: 1.2;">
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──

<img src="https://img.shields.io/badge/version-v0.26.1-brightgreen"> <a href="https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21"></a>
  
This user-friendly tool will support you to build, install, and customize system-specific
TKG/Frogminer source packages from the <a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories.

 + Fast and short commands
 + Interactive TUI mode
 + Integrated online manual
 + Extended `customization.cfg` manager (Beta) 🔥
</pre>

---

<pre style="font-family: 'Courier New', monospace; font-size: 32px; line-height: 1.2;">
<b>INSTALLATION:</b>

  <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <img src="https://img.shields.io/badge/Arch%20Linux-1793D1?logo=archlinux&logoColor=white" alt="Arch Linux" title="Arch Linux Badge">
  - Arch Linux
</pre>
```bash
    # STEP 1: Install
    yay -S tkginstaller-git
    # OR any other AUR helper

    # After installation, you can simply run
    tkginstaller
```
<pre style="font-family: 'Courier New', monospace; font-size: 32px; line-height: 1.2;">
OR:
  <img src="https://img.shields.io/badge/Arch%20Linux-1793D1?logo=archlinux&logoColor=white" alt="Arch Linux" title="Arch Linux Badge"> <img src="https://img.shields.io/badge/Gentoo-54487A?logo=gentoo&logoColor=white" alt="Gentoo" title="Gentoo Badge"> <img src="https://img.shields.io/badge/Debian-A81D33?logo=debian&logoColor=white" alt="Debian" title="Debian Badge"> <img src="https://img.shields.io/badge/Ubuntu-E95420?logo=ubuntu&logoColor=white" alt="Ubuntu" title="Ubuntu Badge"> <img src="https://img.shields.io/badge/Fedora-51A2DA?logo=fedora&logoColor=white" alt="Fedora" title="Fedora Badge"> <img src="https://img.shields.io/badge/openSUSE-73BA25?logo=opensuse&logoColor=white" alt="openSUSE" title="openSUSE Badge"> <img src="https://img.shields.io/badge/Linux-000000?logo=linux&logoColor=white" alt="Linux" title="Linux Badge">
  - All distributions – manual installation
</pre>
```bash
    # Preparation
    mkdir -p /patch/to/tkginstaller
    cd /patch/to/tkginstaller

    # STEP 1: Download with curl
    curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller

    # STEP 2: Optional verify integrity (Recommended)
    curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/SHA256SUMS
    sha256sum -c SHA256SUMS

    # STEP 3: Make script executable
    chmod +x tkginstaller

    # Optional: To make the installer available system-wide after manual installation

    # Method 1: Create a system link
    sudo ln -s /path/to/tkginstaller /usr/bin/tkginstaller

    # Method 2: Create a shell alias or function
    # Add one of these to your ~/.bashrc or ~/.zshrc:

    # As alias:
    alias tkginstaller='/path/to/tkginstaller'

    # OR as function:
    tkginstaller() {
      /path/to/tkginstaller "$@"
    }

    # Now you can run from anywhere
    tkginstaller
```

---

<pre style="font-family: 'Courier New', monospace; font-size: 32px; line-height: 1.2;">
<b>USEAGE:</b>

  <img src="https://img.shields.io/badge/TUI-000000?logo=windowsterminal&logoColor=white" alt="TUI" title="Text UI Badge"> <img src="https://img.shields.io/badge/fzf-finder-13A10E?logo=search&logoColor=white" alt="fzf-finder" title="fzf-finder Badge (with icon)"> <img src="https://img.shields.io/badge/CLI-000000?logo=prompt&logoColor=white" alt="CLI" title="Command Line Interface"> <img src="https://img.shields.io/badge/Terminal-333333?logo=windows-terminal&logoColor=white" alt="Terminal" title="Terminal (nerd font)">
  - Use either an interactive `fzf` menu or a quick direct `terminal` command
</pre>
```bash
    # For a modern and menu-driven experience, simply run
    tkginstaller
```
```bash
    # For quick tasks use one of the direct terminal commands

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

    # Clean up all temporary files and restart installer
    tkginstaller clean

    # Use 'help' or its shortcuts (h, --help, -h)
    tkginstaller help
```

---

<pre style="font-family: 'Courier New', monospace; font-size: 32px; line-height: 1.2;">
This installer script is released under the MIT License.

<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  
Individual TKG/Frogminer packages have their own licenses:
 - See respective repositories at <a href="https://github.com/Frogging-Family">Frogging-Family</a>

🙏 Your support keeps this project alive and improving — thank you!
  
👨‍💻 Developed by DAMACHINE 📧 Contact: christkue79@gmail.com 🌐 Repository: <a href="https://github.com/damachine/tkginstalle">GitHub</a>
</pre>
