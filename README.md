
<pre>
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──

<strong>A simple helper for managing TKG/Frogminer packages from the <a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories</strong>

   <a href="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"><img src="https://img.shields.io/badge/Version-0.29.6-yellow?style=flat&logo=linux"></a> <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <a href="https://github.com/search?q=org%3AFrogging-Family+author%3Adamachine&type=commits"><img src="https://img.shields.io/badge/Frogging--Family-Contributor-green?style=flat&logo=github"></a>
   
<strong>TL:DR</strong>
 - All-in-one and easy to use
    <sup>Build, install/update, and customize</sup>
 - Run via fzf-based <strong><mark>TUI</mark></strong> or direct <strong><mark>CLI</mark></strong> mode
 - Manage any <strong><mark>customization.cfg</mark></strong> file individual 🔥
    <sup>Download, tweak, and compare</sup>
 - Multi-distro support
</pre>

<details>
  <summary>Demo Video</summary>
   
https://github.com/user-attachments/assets/f2ef500c-0d4b-4021-a5b0-e9b5f7306b25
</details>

# 

##### INSTALLATION

```yaml
# Arch Linux-based distributions
# Install via AUR helper (recommended)
yay -S tkginstaller-git
```
```yaml
# All distributions
# Install via automated installation helper
curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | bash
```

# 

##### USAGE

```yaml
# Use fzf-based TUI mode, simply run
tkginstaller

# Use direct CLI mode (skip TUI), run with arguments
tkginstaller [package]

# Use full names or shortcuts:
# (l=linux, n=nvidia, m=mesa, ag=amdgpu, av=amdvlk, w=wine, p=proton, g=gamescope, ge=glibc)
tkginstaller linux      # or shortcut
tkginstaller nvidia
tkginstaller mesa
tkginstaller amdgpu
tkginstaller amdvlk
tkginstaller wine
tkginstaller proton
tkginstaller gamescope
tkginstaller glibc

# Edit a package's configuration file:
tkginstaller [package] [action]

# Use full names or shortcuts: (c=config, e=edit)
tkginstaller config         # Enter TUI to select package
tkginstaller linux config   # or shortcut
tkginstaller config linux
tkginstaller mesa edit

# Clean up all temporary files and restart installer
tkginstaller clean

# Use 'help' or its shortcuts (h, --help, -h)
tkginstaller help
```

# 

##### UNINSTALL

<details>
  <summary>Expand</summary>
   
```yaml
# Arch Linux-based distributions (AUR)
yay -R tkginstaller-git
```
```yaml
# All distributions (installed via install.sh)
# Use the built-in uninstall function
curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | bash -s -- --uninstall

# Or if you have the install.sh downloaded
./install.sh --uninstall
```
```yaml
# All distributions (manual cleanup)
# If the above doesn't work, manually remove files
rm ~/.local/bin/tkginstaller  # or your installation path
rm -rf ~/.tkginstaller
# Remove alias from shell config
sed -i '/# TKG-Installer alias/,+1d' ~/.bashrc ~/.zshrc
source ~/.bashrc ~/.zshrc
```
</details>

# 

###### DISCLAIMER

<pre>
This AIO installer is released under the MIT license.

<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  
Individual TKG/Frogminer packages have their own licenses:
 - See respective repositories at <a href="https://github.com/Frogging-Family">Frogging-Family</a>

<strong><em>💚 Your support ⭐️ keeps this project alive and improving — thank you! 🙏</em></strong>
</pre>
