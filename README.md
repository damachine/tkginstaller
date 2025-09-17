# TKG Installer - A user-friendly script for all TKG packages from the Frogging-Family. 🐸

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Arch Linux](https://img.shields.io/badge/platform-arch--linux-blue?logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![AUR](https://img.shields.io/aur/version/tkginstaller-git?color=1793d1&label=AUR&logo=arch-linux)](https://aur.archlinux.org/packages/tkginstaller-git)
![Bash](https://img.shields.io/badge/language-bash-blue?logo=gnu-bash)
[![Issues](https://img.shields.io/github/issues/damachine/tkginstaller)](https://github.com/damachine/tkginstaller/issues)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21)](https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-blue?logo=github-sponsors)](https://github.com/sponsors/damachine)

## Description

This wrapper script makes it easy to install packages from the [Frogging-Family](https://github.com/Frogging-Family) repository. It provides an interactive menu system for building and installing various TKG packages:

![TKG Installer Screenshot](images/banner.jpg)

## Prerequisites

The script automatically checks for the following core dependencies:
- `fzf` - Fuzzy finder for the interactive menu
- `gcc` - Compiler for building packages
- `git` - Version control system

Optional tools (used if available):
- Any text editor for configuration files (the script respects the $EDITOR environment variable and falls back to `nano` if not set) — examples: `nano`, `vim`, `code`.
- `bat` - Alternative for "cat" with syntax highlighting
- `onefetch` - Git repository information display (optional)

## Installation

### Install TKG Installer

#### Arch Linux (Recommended)

[![AUR](https://img.shields.io/aur/version/tkginstaller-git?color=1793d1&label=AUR&logo=arch-linux)](https://aur.archlinux.org/packages/tkginstaller-git)

- **Using an AUR helper (recommended):**
   ```bash
   # STEP 1: Install
   yay -S tkginstaller-git
   #OR any other AUR helper

   # STEP 2: After installation, you can simply run:
   tkginstaller

   # Show all available commands and shortcuts (very useful!)
   tkginstaller help
   ```

#### Alternative Installation
1. Download only the script (no git required):
   ```bash
   # STEP 1: Pre install
   mkdir -p /patch/to/tkginstaller && cd /patch/to/tkginstaller

   # STEP 2: Download and make script executable
   wget https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller.sh
   chmod +x tkginstaller.sh

   # OR STEP 2: Download with curl and make script executable
   curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller.sh
   chmod +x tkginstaller.sh
   ```

## Usage

You can run the script in two ways:

### Interactive Mode (Menu)
```bash
tkginstaller
```

### Command Mode (Direct)
Skip the menu and run specific actions directly:
```bash
# Show all available commands and shortcuts (very useful!)
tkginstaller help
```

### Configuration-Menue

The **Config** option provides an interactive editor for TKG configuration files:
- Edit all relevant TKG configuration files (e.g. for Linux-TKG, Nvidia-TKG, Mesa-TKG, Wine-TKG, Proton-TKG)
- Preview the relevant TKG configuration files
- Uses your preferred editor via `$EDITOR`

### Quick Alias

If you installed manually (not via AUR), add this to your `~/.bashrc` or `~/.zshrc` for easy access:
```bash
# Examples
<<<<<<< HEAD
tkginstaller() {
    bash -c '/path/to/tkginstaller.sh'
}
# OR
alias tkginstaller="bash -c '/path/to/tkginstaller.sh'"
=======
youralias() {
    bash -c '/path/to/tkginstaller.sh'
}
# OR
alias youralias="bash -c '/path/to/tkginstaller.sh'"
>>>>>>> 66c903dcacd4a65e9d971032e0042d0f47706ab1

# System link (optional)
# To make the installer available system-wide, create a symlink:
sudo ln -s /path/to/tkginstaller.sh /usr/bin/tkginstaller

# Now you can run 'tkginstaller' from anywhere.

```

## Notes

The script:

- is specifically designed for Arch Linux and its derivatives
- uses `makepkg` to compile packages
- performs automatic system updates before installation
- deletes the downloaded files after use
- supports only one concurrent execution

If you need help, open an issue at https://github.com/damachine/tkginstaller/issues

---

## ⚠️ Disclaimer
This software is provided "as is", without warranty of any kind, express or implied.
I do not guarantee that it will work as intended on your system.

---

## License

This installer script is released under the **MIT License**.

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

Individual TKG packages have their own licenses:
- See respective repositories at https://github.com/Frogging-Family

---

## 💝 Support the Project

If you find CoolerDash useful and want to support its development:

- ⭐ **Star this repository** on GitHub
- 🐛 **Report bugs** and suggest improvements
- 🔄 **Share** the project with others
- 📝 **Contribute** code or documentation
- [![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-blue?logo=github-sponsors)](https://github.com/sponsors/damachine)

> *🙏 Your support keeps this project alive and improving — thank you!.*

---

👨‍💻 Developed by **DAMACHINE** 📧 Contact: christkue79@gmail.com 🌐 Repository: [GitHub](https://github.com/damachine/tkginstaller)
