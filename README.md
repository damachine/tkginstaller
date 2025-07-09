# TKG Installer

A comprehensive installer script for all TKG packages from the Frogging-Family.

## Description

This repository contains an interactive installer script for various TKG (The Kegel Group) packages:

### 🧠 **Linux-TKG**
- Custom Linux kernels with gaming optimizations
- Various schedulers and performance patches

### 🎮 **Nvidia-TKG** 
- Nvidia graphics drivers (open-source or proprietary)
- Optimized for gaming and performance

### 🧩 **Mesa-TKG**
- Open-source graphics drivers for AMD and Intel
- Advanced gaming features and performance optimizations

### 🍷 **Wine-TKG**
- Windows compatibility layer with additional patches
- Optimized for gaming and application compatibility

### 🧪 **Proton-TKG**
- Steam-compatible Windows compatibility layer
- Advanced gaming features and Valve patches

## Contents

- `tkg_install`: Main installer script with interactive menu
- `.config/`: Configuration files for colors and preview texts
- Automatic dependency checking and system updates

## Features

- 🎛️ **Interactive Menu** with fzf-based selection
- 📋 **Live Preview** of available packages
- 🔒 **Safe Execution** with lockfile system
- 🧹 **Automatic Cleanup** of temporary files
- ✅ **Dependency Check** for required tools
- 🎨 **Colorized Output** for better readability

## Prerequisites

The script automatically checks for the following dependencies:
- `fzf` - Fuzzy finder for the interactive menu
- `yay` - AUR helper for Arch Linux
- `paccache` - Package cache management
- `bleachbit` - System cleanup
- `fastfetch` - System information
- `gcc` - Compiler for building packages
- `git` - Version control
- `onefetch` - Git repository information

## Installation

1. Clone repository:
   ```bash
   git clone <repository-url> tkginstaller
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

- **Linux**: Installs Linux-TKG kernel
- **Nvidia**: Installs Nvidia-TKG drivers
- **Linux+Nvidia**: Combined installation of kernel and Nvidia drivers
- **Mesa**: Installs Mesa-TKG for AMD/Intel graphics
- **Wine**: Installs Wine-TKG for Windows applications
- **Proton**: Installs Proton-TKG for Steam gaming
- **Clean**: Cleans temporary files and restarts
- **Exit**: Exits the script

## Source

Based on the Frogging-Family project: https://github.com/Frogging-Family

## Notes

- The script is specifically designed for Arch Linux
- Uses `makepkg` to compile packages
- Automatic system updates before installation
- Supports only one concurrent execution (lockfile system)

## License

See the respective license files of the Frogging-Family projects.
