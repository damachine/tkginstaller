
<pre>
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──

<strong>This wrapper script is intended to simplify the building, installing, and 
customizing the TKG/Frogminer source-based packages from the
<a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories.</strong>

   <a href="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"><img src="https://img.shields.io/badge/Version-0.26.6-yellow?style=flat&logo=linux"></a> <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <a href="https://github.com/search?q=org%3AFrogging-Family+author%3Adamachine&type=commits"><img src="https://img.shields.io/badge/Frogging--Family-Contributor-green?style=flat&logo=github"></a>
   
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
```yaml
# OR: Install all manual
# Preparation
mkdir -p /patch/to/tkginstaller
cd /patch/to/tkginstaller

# STEP 1: Download with curl
curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller

# STEP 2: Optional verify integrity (Recommended)
curl -O https://raw.githubusercontent.com/damachine/tkginstaller/master/SHA256SUMS
sha256sum -c SHA256SUMS

# STEP 3: Make script executable
chmod +x tkginstaller

# Optional: To make the installer available system-wide after manual installation

# Method 1: Create a system link
sudo ln -s /path/to/tkginstaller /usr/bin/tkginstaller

# Method 2: Create a shell alias or function
# Add one of these to your ~/.bashrc or ~/.zshrc:

# As alias:
alias tkginstaller='/path/to/tkginstaller'

# OR as function:
tkginstaller() {
  /path/to/tkginstaller "$@"
}

# Now you can run from anywhere:
tkginstaller
```
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

tkginstaller linux      # or 'tkginstaller l'
tkginstaller nvidia     # or 'tkginstaller n'
tkginstaller mesa       # or 'tkginstaller m'
tkginstaller wine       # or 'tkginstaller w'
tkginstaller proton     # or 'tkginstaller p'

# Syntax: tkginstaller [package] [action]
# Use full names or shortcuts (c, e for config/edit)

# Edit a package's configuration file:
tkginstaller linux config   # or 'tkginstaller l c'
tkginstaller config linux   # or 'tkginstaller c l'
tkginstaller mesa edit      # or 'tkginstaller m e'

# Clean up all temporary files and restart installer
tkginstaller clean

# Use 'help' or its shortcuts (h, --help, -h)
tkginstaller help
```

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
