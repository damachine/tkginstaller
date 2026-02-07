
<pre>
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  🐸  ──

<strong>A small helper that makes working with <a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories easy</strong>

   <a href="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"><img src="https://img.shields.io/badge/Version-0.30.2-yellow?style=flat&logo=linux"></a> <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <a href="https://github.com/search?q=org%3AFrogging-Family+author%3Adamachine&type=commits"><img src="https://img.shields.io/badge/Frogging--Family-Collaborator-green?style=flat&logo=github"></a>
   
<strong>TL;DR</strong>
 - All frog packages in one pond 🐸 
 - Run quick one-liner <strong><mark>CLI</mark></strong> commands or an interactive fzf-finder <strong><mark>TUI</mark></strong>
 - Built-in <strong><mark>customization.cfg</mark></strong> manager
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
# Use fzf-finder TUI mode, simply run
tkginstaller

# Use direct one-liner CLI mode (skip TUI), run with arguments
tkginstaller [package]
# e.g
tkginstaller linux      # or shortcut
tkginstaller nvidia

# Edit a package's configuration file
tkginstaller [config] [package]
# e.g
tkginstaller config         # Enter fzf-finder TUI to select package
tkginstaller config linux   # or shortcut

# Clean up all temporary files
tkginstaller clean

# Show help
tkginstaller help

# All names and shortcuts to use:
# l=linux, n=nvidia, m=mesa, ag=amdgpu, av=amdvlk, w=wine, p=proton, g=gamescope, ge=glibc
# c=config, e=edit
# h, --help, -h
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
# Manually remove all files
rm /patch/to/tkginstaller     # where you put it
rm -rf ~/.tkginstaller        # cache folder
# Remove alias from shell config
sed -i '/# TKG-Installer alias/,+1d' ~/.bashrc ~/.zshrc
source ~/.bashrc ~/.zshrc
```
</details>

# 

###### DISCLAIMER

<pre>
This tool is released under the MIT license.

<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  
Individual TKG/Frogminer packages have their own licenses:
 - See respective repositories at <a href="https://github.com/Frogging-Family">Frogging-Family</a>

<strong><em>💚 Your support ⭐️ keeps this project alive and improving — thank you! 🙏</em></strong>
</pre>
