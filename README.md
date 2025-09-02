# TKG Installer - A user-friendly script for all TKG packages from the Frogging-Family. 🐸

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21)](https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

## Description

This wrapper script makes it easy to install packages from the [Frogging-Family](https://github.com/Frogging-Family) repository. It provides an interactive menu system for building and installing various TKG packages:

### 🧠 **Linux-TKG**
- [https://github.com/Frogging-Family/linux-tkg](https://github.com/Frogging-Family/linux-tkg)

### 🎮 **Nvidia-TKG** 
- [https://github.com/Frogging-Family/nvidia-all](https://github.com/Frogging-Family/nvidia-all)

### 🧩 **Mesa-TKG**
- [https://github.com/Frogging-Family/mesa-git](https://github.com/Frogging-Family/mesa-git)

### 🍷 **Wine-TKG**
- [https://github.com/Frogging-Family/wine-tkg-git](https://github.com/Frogging-Family/wine-tkg-git)

### 🧪 **Proton-TKG**
- [https://github.com/Frogging-Family/wine-tkg-git/tree/master/proton-tkg](https://github.com/Frogging-Family/wine-tkg-git/tree/master/proton-tkg)

## Features

- 🎛️ **Interactive Menu** with fzf-based selection
- 📋 **Live Preview** of available packages
- ⚙️ **Configuration Editor** with interactive TKG config file editing
- 🔒 **Safe Execution** with lockfile system
- 🧹 **Automatic Cleanup** of temporary files
- ✅ **Dependency Check** for required tools
- 🎨 **Colorized Output** for better readability
- 🌐 **Portable Design** - works from any directory

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

1. Download only the script (no git required):
   ```bash
   cd /path/to/download   
   # Example: mkdir -p ~/tkg_installer && cd ~/tkg_installer
   wget https://raw.githubusercontent.com/damachine/tkginstaller/master/tkg_install.sh
   chmod +x tkg_install.sh
   ```

   Or with curl:
   ```bash
   curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/tkg_install.sh
   chmod +x tkg_install.sh
   ```

1b. (Alternative) Clone repository:
   ```bash
   git clone https://github.com/damachine/tkginstaller.git
   cd tkginstaller
   chmod +x tkg_install.sh
   ```

2. Start installer:
   ```bash
   ./tkg_install.sh
   ```

## Quick Alias

Add this to your `~/.bashrc` or `~/.zshrc` for easy access:
```bash
alias tkg_install='sudo -u $USER sh -c "/home/$USER/.tkg/tkg_install.sh"'
```
Then just run:
```bash
tkg_install
```

## Usage

The script provides an interactive menu with the following options:

![TKG Installer Screenshot](images/screenshot.png)

- **Linux**: Installs Linux-TKG kernel
- **Nvidia**: Installs Nvidia-TKG drivers
- **Linux+Nvidia**: Combined installation of kernel and Nvidia drivers
- **Mesa**: Installs Mesa-TKG for AMD/Intel graphics
- **Wine**: Installs Wine-TKG for Windows applications
- **Proton**: Installs Proton-TKG for Steam gaming
- **Config**: Opens configuration editor for TKG packages
- **Clean**: Cleans temporary files and restarts
- **Exit**: Exits the script

### Configuration Editor

The **Config** option provides an interactive editor for TKG configuration files:
- Edit Linux-TKG kernel configuration
- Modify Nvidia-TKG driver settings
- Adjust Mesa-TKG graphics options
- Customize Wine-TKG compatibility settings
- Uses your preferred editor via `$EDITOR`

## Source

Based on the Frogging-Family project: https://github.com/Frogging-Family

## Notes

- The script is specifically designed for Arch Linux
- Uses `makepkg` to compile packages
- Automatic system updates before installation
- The downloaded files are deleted after use!
- Supports only one concurrent execution (lockfile system)

## License

This installer script is released under the **MIT License**.

Individual TKG packages have their own licenses:
- See respective repositories at https://github.com/Frogging-Family
