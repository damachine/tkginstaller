
<pre>
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──

<strong>This AIO installer is intended to serve as an helper to
perform the building, installing, and customizing of the
TKG/Frogminer packages from the <a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories.</strong>

   <a href="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"><img src="https://img.shields.io/badge/Version-0.28.7-yellow?style=flat&logo=linux"></a> <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <a href="https://github.com/search?q=org%3AFrogging-Family+author%3Adamachine&type=commits"><img src="https://img.shields.io/badge/Frogging--Family-Contributor-green?style=flat&logo=github"></a>
   
Features
 <strong>- Easy-to-use, AIO package manager for the TKG repositories</strong>
 <strong>- Uses fzf TUI or DIRECT command-line mode</strong>
 <strong>- Supports multiple distributions</strong>
 <strong>- Manage each <mark>customization.cfg</mark> package file (Beta) 🔥</strong>
    <sub>Download, adjust and compare</sub>
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
# Use fzf TUI mode, simply run
tkginstaller

# Use DIRECT mode (skip TUI), run with arguments
tkginstaller [package]

# Use full names or shortcuts (l, n, m, w, p)
tkginstaller linux      # or shortcut
tkginstaller nvidia
tkginstaller mesa
tkginstaller wine
tkginstaller proton

# Edit a package's configuration file:
tkginstaller [package] [action]

# Use full names or shortcuts (c, e for config/edit)
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
# All distributions (manual installation)
# Simply remove the script and optional cache folder
# If installed manually, also remove the symlink and/or alias/function
rm /path/to/tkginstaller
# Remove cache directory
rm -rf ~/.tkginstaller
# Remove alias/function from ~/.bashrc or ~/.zshrc (if added)
sed -i '/tkginstaller/d' ~/.bashrc ~/.zshrc
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
