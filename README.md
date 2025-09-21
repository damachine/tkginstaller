# TKG Installer 🐸

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Arch Linux](https://img.shields.io/badge/platform-arch--linux-blue?logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![AUR](https://img.shields.io/aur/version/tkginstaller-git?color=1793d1&label=AUR&logo=arch-linux)](https://aur.archlinux.org/packages/tkginstaller-git)
![Bash](https://img.shields.io/badge/language-bash-blue?logo=gnu-bash)
[![Issues](https://img.shields.io/github/issues/damachine/tkginstaller)](https://github.com/damachine/tkginstaller/issues)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21)](https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-blue?logo=github-sponsors)](https://github.com/sponsors/damachine)

---

#### This wrapper script makes it easy to manage packages from the Frogging-Family repository. It provides both an interactive mode and a command-line mode for building and installing various TKG packages such as Kernel, Nvidia, Mesa, Wine, Proton. Users also have the option to directly edit the package configuration before building.

![TKG Installer Banner](images/banner.jpg)

![TKG Installer Screenshot](images/tkginstaller.png)
[🎬 Demo-Video](images/tkginstaller.gif)

---

## 📝 Prerequisites

#### The script automatically checks for the following core dependencies:

- **`fzf`** - Fuzzy finder for the interactive menu
- **`gcc`** - Compiler for building packages
- **`git`** - Version control system

#### ⭐ Optional tools (very useful!):

- **`bat`** - Alternative for "cat" with syntax highlighting
- **`curl`, `wget`** - Fetching preview content
- **`glow`** - Converts Markdown in terminal
- **`llvm`** - Useful for building and debugging some TKG packages
- Any text editor for configuration files (the script respects the $EDITOR environment variable and falls back to **`nano`** if not set) — examples: **`nano`, `vim`.**
- **`onefetch`** - Git repository information display

---

## 🛠️ Installation

#### Arch Linux (Recommended)

[![AUR](https://img.shields.io/aur/version/tkginstaller-git?color=1793d1&label=AUR&logo=arch-linux)](https://aur.archlinux.org/packages/tkginstaller-git)

- Using an AUR helper:
  
   ```bash
   # STEP 1: Install
   yay -S tkginstaller-git
   #OR any other AUR helper

   # After installation, you can simply run:
   tkginstaller

   # Show all available commands and shortcuts (very useful!)
   tkginstaller help
   ```

#### Manual Installation

- Download only the script:
  
   ```bash
   # STEP 1: Pre install
   mkdir -p /patch/to/tkginstaller && cd /patch/to/tkginstaller

   # STEP 2: Download and make script executable
   wget https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller.sh
   chmod +x tkginstaller.sh

   # OR: Download with curl and make script executable
   curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller.sh
   chmod +x tkginstaller.sh
   ```

---

## 🚀 Usage

> [!IMPORTANT]
> You can run the script in two ways:

#### Interactive (Menu-mode)
```bash
tkginstaller
```

#### Commandline (Direct-mode)

- Skip the menu and run specific actions directly:

```bash
Usage: tkginstaller [linux|l|nvidia|n|mesa|m|wine|w|proton|p|linuxnvidia|ln|nl|linux+nvidia|config|clean|exit]
Shortcuts: l=linux, n=nvidia, m=mesa, w=wine, p=proton, ln/linux+nvidia=Linux+Nvidia combo
Examples:
  tkginstaller linux    # Install Linux-TKG
  tkginstaller nvidia   # Install Nvidia-TKG
  tkginstaller mesa     # Install Mesa-TKG
  tkginstaller wine     # Install Wine-TKG
  tkginstaller proton   # Install Proton-TKG

# Show all available commands and shortcuts (useful!)
tkginstaller help
```

---

### ⚙️ Configuration

- The **`Config-TKG`** option provides an interactive editor for TKG configuration files:
- Edit all relevant TKG configuration files (e.g. for Linux-TKG, Nvidia-TKG, Mesa-TKG, Wine-TKG, Proton-TKG)
- Preview the relevant TKG configuration files
- Uses your preferred editor via `$EDITOR`

---

> [!TIP]
> Quick access: 
> - If you installed manually (not via AUR), add this to your `~/.bashrc` or `~/.zshrc` for easy access:

   ```bash
   # Examples
   tkginstaller() {
      bash -c '/path/to/tkginstaller.sh'
   }
   # OR
   alias tkginstaller="bash -c '/path/to/tkginstaller.sh'"

   # System link
   # To make the installer available system-wide, create a symlink and skip alias:
   sudo ln -s /path/to/tkginstaller.sh /usr/bin/tkginstaller

   # Now you can run 'tkginstaller' from anywhere.
   ```

---

> [!NOTE]
> The script:
> - is specifically designed for Arch Linux and its derivatives
> - uses for now only `makepkg` to compile packages
> - performs automatic system updates before installation
> - deletes the downloaded files after use
> - supports only one concurrent execution
> - download missing config files

If you need help, open an issue at https://github.com/damachine/tkginstaller/issues

---

## ⚠️ Disclaimer
This software is provided "as is", without warranty of any kind, express or implied.
I do not guarantee that it will work as intended on your system.

---

## 📄 License

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
