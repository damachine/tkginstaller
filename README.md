
# TKG-Installer 🐸

<p align="left">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  <img src="https://img.shields.io/badge/language-bash-blue?logo=gnu-bash">
  <a href="https://kernel.org/"><img src="https://img.shields.io/badge/Platform-Linux-green.svg"></a>
  <a href="https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21"></a>
</p>

---

## ⭐ Features
- **Manage the popular TKG packages `Kernel`, `Nvidia`, `Mesa`, `Wine`, `Proton` from the [Frogging-Family](https://github.com/Frogging-Family) repositories.** 
- **Interactive Fuzzy finder `fzf` menue mode.**
- **Quick direct command-line mode.**
- **Preview readme and configuration.**
- **Edit configuration files using your preferred editor.**  
- **Optional download configuration files.**
- **Multi-Distribution Support.**

##### **[🎬 Demo-Video](images/tkginstaller.gif)**

---

## 🛠️ Installation

#### Arch Linux

[![AUR](https://img.shields.io/aur/version/tkginstaller-git?color=1793d1&label=AUR&logo=arch-linux)](https://aur.archlinux.org/packages/tkginstaller-git)

- Using an AUR helper (Recommended):
  
   ```bash
   # STEP 1: Install
   yay -S tkginstaller-git
   #OR any other AUR helper

   # After installation, you can simply run:
   tkginstaller

   # Show all available commands and shortcuts (very useful!)
   tkginstaller help
   ```

#### All Distributions

- Manual installation:

   ```bash
   # STEP 1: Preparation
   mkdir -p /patch/to/tkginstaller
   cd /patch/to/tkginstaller

   # STEP 2: Download with wget
   wget https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller.sh
   # OR: Download with curl
   curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller.sh

   # STEP 3: Make script executable
   chmod +x tkginstaller.sh

   # STEP 4: Optional (Recommended)
   # Quick access: Create a system link 
   # To make the installer available system-wide, create a symlink and skip alias:
   sudo ln -s /path/to/tkginstaller.sh /usr/bin/tkginstaller
   # OR: Create a alias
   # If you installed manually, add this to your `~/.bashrc` or `~/.zshrc` for easy access:
   tkginstaller() {
      bash -c '/path/to/tkginstaller.sh'
   }
   # OR:
   alias tkginstaller="bash -c '/path/to/tkginstaller.sh'"

   # Now you can run from anywhere:
   tkginstaller
   ```

- Optional tools (Recommended):

> - **`nano`, `micro`, `vim`** - An text editor for configuration files. ***Usage: Set the `$EDITOR` environment variable. Howto: [ArchWiki](https://wiki.archlinux.org/title/Environment_variables#) Fallback: `nano` if installed***
> - **`onefetch`** - Git repository information display.

---

## 🚀 Usage

- #### Interactive (Menu-mode)
   ```bash
   tkginstaller
   ```

- #### Command-line (Direct-mode)

   ```bash
   # Skip the menu and run specific actions directly:
   # Examples:
   tkginstaller linux    # Install Linux-TKG
   tkginstaller nvidia   # Install Nvidia-TKG
   tkginstaller mesa     # Install Mesa-TKG
   tkginstaller wine     # Install Wine-TKG
   tkginstaller proton   # Install Proton-TKG

   # Show all available commands and shortcuts!
   tkginstaller help
   ```

---

> [!TIP]
> Contribute and suggest improvements. Welcome ⭐ at **[Discussions](https://github.com/damachine/tkginstaller/discussions)**  
> If you need help, open an **[Issues](https://github.com/damachine/tkginstaller/issues)**
>
> <a href="https://github.com/damachine/tkginstaller/issues"><img src="https://img.shields.io/github/issues/damachine/tkginstaller"></a>

---

## ⚠️ Disclaimer
This software is provided "as is", without warranty of any kind, express or implied.
I do not guarantee that it will work as intended on your system.

## 📄 License

This installer script is released under the **MIT License**.

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

Individual TKG packages have their own licenses:
- See respective repositories at [https://github.com/Frogging-Family](https://github.com/Frogging-Family)

---

## 💝 Support the Project

If you find TKG Installer useful and want to support its development:

- ⭐ **Star this repository** on GitHub.
- 🐛 **Report bugs** and suggest improvements.
- 🔄 **Share** the project with others.
- 📝 **Contribute** code or documentation.
- [![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-blue?logo=github-sponsors)](https://github.com/sponsors/damachine)

> *🙏 Your support keeps this project alive and improving — thank you!.*

#### ⭐ Stargazers over time
[![Stargazers over time](https://starchart.cc/damachine/tkginstaller.svg?variant=adaptive)](https://starchart.cc/damachine/tkginstaller)

---

👨‍💻 Developed by **DAMACHINE** 📧 Contact: christkue79@gmail.com 🌐 Repository: [GitHub](https://github.com/damachine/tkginstaller)
