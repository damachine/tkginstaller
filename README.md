
<pre style="font-family: 'Courier New', monospace;">
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──

<img src="https://img.shields.io/badge/version-v0.26.1-brightgreen"> <a href="https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21"></a>
  
This user-friendly tool allows you to easily build, install, and customize system-specific
TKG/Frogminer source packages from the <a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories.

 + Fast and short commands
 + Interactive TUI mode
 + Integrated online manual
 + Extended `customization.cfg` manager (Beta) 🔥
</pre>

---

<pre style="font-family: 'Courier New', monospace;">
<b>INSTALLATION</b>

  <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <img src="https://img.shields.io/badge/Arch%20Linux-1793D1?logo=archlinux&logoColor=white" alt="Arch Linux" title="Arch Linux Badge"> <img src="https://img.shields.io/badge/Gentoo-54487A?logo=gentoo&logoColor=white" alt="Gentoo" title="Gentoo Badge"> <img src="https://img.shields.io/badge/Debian-A81D33?logo=debian&logoColor=white" alt="Debian" title="Debian Badge"> <img src="https://img.shields.io/badge/Ubuntu-E95420?logo=ubuntu&logoColor=white" alt="Ubuntu" title="Ubuntu Badge"> <img src="https://img.shields.io/badge/Fedora-51A2DA?logo=fedora&logoColor=white" alt="Fedora" title="Fedora Badge"> <img src="https://img.shields.io/badge/openSUSE-73BA25?logo=opensuse&logoColor=white" alt="openSUSE" title="openSUSE Badge"> <img src="https://img.shields.io/badge/Linux-000000?logo=linux&logoColor=white" alt="Linux" title="Linux Badge">
  - Arch Linux (Full support)
  - Other distributions (Linux kernel, Wine and Proton packages support by Frogging-Family)
</pre>
```bash
    # Arch based distro
    # Install via AUR helper
    yay -S tkginstaller-git
    # OR any other AUR helper

    # OR:
    # Automated installation helper
    curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | bash

    # After installation, you can simply run
    tkginstaller
```

---

<pre style="font-family: 'Courier New', monospace;">
<b>USAGE:</b>

  <img src="https://img.shields.io/badge/TUI-000000?logo=windowsterminal&logoColor=white" alt="TUI" title="Text UI Badge"> <img src="https://img.shields.io/badge/fzf-finder-13A10E?logo=search&logoColor=white" alt="fzf-finder" title="fzf-finder Badge (with icon)"> <img src="https://img.shields.io/badge/CLI-000000?logo=prompt&logoColor=white" alt="CLI" title="Command Line Interface"> <img src="https://img.shields.io/badge/Terminal-333333?logo=windows-terminal&logoColor=white" alt="Terminal" title="Terminal (nerd font)">
  - Use either an interactive `fzf` menu or a quick direct `terminal` command
</pre>
```bash
    # For a modern and menu-driven experience, simply run
    tkginstaller
```
```bash
    # For a quick tasks use one of the direct terminal commands

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

<pre style="font-family: 'Courier New', monospace;">
This installer script is released under the MIT License.

<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  
Individual TKG/Frogminer packages have their own licenses:
 - See respective repositories at <a href="https://github.com/Frogging-Family">Frogging-Family</a>

<b>Your support keeps this project alive and improving — thank you! 🙏</b>
  
👨‍💻 Developed by DAMACHINE 📧 Contact: christkue79@gmail.com 🌐 Repository: <a href="https://github.com/damachine/tkginstalle">GitHub</a>
</pre>
