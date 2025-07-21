# TKG Installer 

A user-friendly wrapper script for all TKG packages from the Frogging-Family. 🐸

## Description

This wrapper script makes it easy to install packages from the [Frogging-Family](https://github.com/Frogging-Family) repository. It provides an interactive menu system for building and installing various TKG packages:

### 🧠 **Linux-TKG**
- Custom Linux kernels with gaming optimizations
- Various schedulers and performance patches
- [https://github.com/Frogging-Family/linux-tkg](https://github.com/Frogging-Family/linux-tkg)

### 🎮 **Nvidia-TKG** 
- Nvidia graphics drivers (open-source or proprietary)
- Optimized for gaming and performance
- [https://github.com/Frogging-Family/nvidia-all](https://github.com/Frogging-Family/nvidia-all)

### 🧩 **Mesa-TKG**
- Open-source graphics drivers for AMD and Intel
- Advanced gaming features and performance optimizations
- [https://github.com/Frogging-Family/mesa-git](https://github.com/Frogging-Family/mesa-git)

### 🍷 **Wine-TKG**
- Windows compatibility layer with additional patches
- Optimized for gaming and application compatibility
- [https://github.com/Frogging-Family/wine-tkg-git](https://github.com/Frogging-Family/wine-tkg-git)

### 🧪 **Proton-TKG**
- Steam-compatible Windows compatibility layer
- Advanced gaming features and Valve patches
- [https://github.com/Frogging-Family/wine-tkg-git/tree/master/proton-tkg](https://github.com/Frogging-Family/wine-tkg-git/tree/master/proton-tkg)

## Contents

- `tkg_install`: Main wrapper script with interactive menu
- `.config/`: Configuration files for colors and preview texts
- Automatic dependency checking and system updates

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
- `nano` - Text editor for configuration files
- `bat` - Alternative for "cat" with more syntax highlight

Optional tools (used if available):
- `onefetch` - Git repository information display (optional)
- `paccache` - Pacman cache cleaning (optional)
- `bleachbit` - System cleaningg for local language files (optional)

## Installation

1. Clone repository:
   ```bash
   git clone https://github.com/damachine/tkginstaller.git
   cd tkginstaller
   ```

2. Make script executable:
   ```bash
   chmod +x tkg_install
   ```

3. Start installer:
   ```bash
   ./tkg_install
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
- Uses `nano` editor with user-friendly interface

## Source

Based on the Frogging-Family project: https://github.com/Frogging-Family

## Notes

- The script is specifically designed for Arch Linux
- Uses `makepkg` to compile packages
- Automatic system updates before installation
- Supports only one concurrent execution (lockfile system)

## License

This installer script is released under the **MIT License**.

Individual TKG packages have their own licenses:
- See respective repositories at https://github.com/Frogging-Family
