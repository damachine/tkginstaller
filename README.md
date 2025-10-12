
# TKG-Installer 🐸

### Manage the popular TKG packages (Kernel, Nvidia, Mesa, Wine, Proton) from the [Frogging-Family](https://github.com/Frogging-Family) repositories.

<p align="left">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  <img src="https://img.shields.io/badge/language-bash-blue?logo=gnu-bash">
  <a href="https://kernel.org/"><img src="https://img.shields.io/badge/Platform-Linux-green.svg"></a>
  <a href="https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21"></a>
</p>

---

## ⭐ Features

- **Dual Mode Operation**: Choose between an interactive `fzf`-based menu or a fast direct command-line mode.
- **Direct Config Editing**: Quickly open and edit package configurations directly from the command line (e.g., `tkginstaller linux config`).
- **Smart Previews**: View official READMEs and local configurations directly in the `fzf` preview pane.
- **Auto-Setup**: Automatically downloads missing configuration files.
- **Multi-Distro Support**: Compatible with Arch-based systems and other distributions.
- **Lightweight & Simple**: A single, easy-to-use Bash script with minimal dependencies.

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

- Dependencies:

> - **`bat`**: For syntax highlighting in the preview window.
> - **`curl`**: For downloading files and previews.
> - **`glow`**: For preview Readme.md files in the terminal.
> - **`fzf`**: Powers the interactive menu.
> - **`git`**: For cloning the TKG repositories.

- Optional tools (Recommended):

> - **`onefetch`**: To display Git repository information during the build process.
> - **`nano`, `vim`, `micro`, etc.** A text editor: For editing configuration files.
> - The script uses the `$EDITOR` environment variable. If not set, it falls back to `nano`.

---

## 🚀 Usage

- #### Interactive (Menu-mode)

> For a user-friendly, menu-driven experience, simply run:

>   ```bash
>   tkginstaller
>   ```

- #### Command-line (Direct-mode)

> For quick, automated tasks, use direct commands. This mode skips the interactive menu.

>   ```bash
>   # Syntax: tkginstaller [package]
>   # Use full names or shortcuts (l, n, m, w, p)
>
>   tkginstaller linux      # or 'tkginstaller l'
>   tkginstaller nvidia     # or 'tkginstaller n'
>   tkginstaller mesa       # or 'tkginstaller m'
>   tkginstaller wine       # or 'tkginstaller w'
>   tkginstaller proton     # or 'tkginstaller p'
>
>   # Syntax: tkginstaller [package] [action]
>   # Use full names or shortcuts (c, e for config/edit)
>
>   # Edit a package's configuration file:
>   tkginstaller linux config   # or 'tkginstaller l c'
>
>   # Use 'help' or its shortcuts (h, --help, -h)
>   tkginstaller help
>   ```

---

> [!TIP]
> ### Have a question or an idea?
> - **Suggest improvements** or discuss new features in our **[Discussions](https://github.com/damachine/tkginstaller/discussions)**.
> - **Report a bug** or request help by opening an **[Issue](https://github.com/damachine/tkginstaller/issues)**.
>
> <a href="https://github.com/damachine/tkginstaller/discussions"><img src="https://img.shields.io/github/discussions/damachine/tkginstaller?style=flat-square&logo=github&label=Discussions"></a> <a href="https://github.com/damachine/tkginstaller/issues"><img src="https://img.shields.io/github/issues/damachine/tkginstaller?style=flat-square&logo=github&label=Issues"></a>

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
