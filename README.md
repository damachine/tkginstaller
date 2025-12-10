
<pre>
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──

<strong>This AIO helper script is intended to serve as an entry point
to perform the building, installing, and customizing of the
TKG/Frogminer packages from the <a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories.</strong>

   <a href="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"><img src="https://img.shields.io/badge/Version-0.27.9-yellow?style=flat&logo=linux"></a> <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <a href="https://github.com/search?q=org%3AFrogging-Family+author%3Adamachine&type=commits"><img src="https://img.shields.io/badge/Frogging--Family-Contributor-green?style=flat&logo=github"></a>
   
Features
 <strong>- User-friendly interactive control</strong>
 <strong>- Use commands for automated processes</strong>
 <strong>- Modern stylish menu-driven TUI client</strong>
    <sub>Integrated preview and editor</sub>
    <sub>Read online manual</sub>
 <strong>- One place to manage the <mark>customization.cfg</mark> files (Beta) 🔥</strong>
    <sub>Download missing files</sub>
    <sub>Adjust the settings to your liking</sub>
    <sub>Compare your local files with the online ones</sub>
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
`````
````yaml
# All distributions
# Install via automated installation helper
curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | bash
`````

# 

##### USAGE

```yaml
# TUI mode, simply run
tkginstaller
```
```yaml
# DIRECT mode, terminal commands to run

# Syntax: tkginstaller [package]
# Use full names or shortcuts (l, n, m, w, p)

tkginstaller linux      # or shortcut
tkginstaller nvidia
tkginstaller mesa
tkginstaller wine
tkginstaller proton

# Syntax: tkginstaller [package] [action]
# Use full names or shortcuts (c, e for config/edit)

# Edit a package's configuration file:
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
This installer script is released under the MIT license.

<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  
Individual TKG/Frogminer packages have their own licenses:
 - See respective repositories at <a href="https://github.com/Frogging-Family">Frogging-Family</a>

<strong>💚 Your support keeps this project alive and improving — thank you! 🙏</strong>
  
👨‍💻 Developed by DAMACHINE 📧 Contact: christkue79@gmail.com 🌐 Repository: <a href="https://github.com/damachine/tkginstalle">GitHub</a>
</pre>
