
<pre>
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸  ──

<strong>This script have the goal to help you with the full process 
of building, installing, and customizing the TKG/Frogminer
source-based packages from the <a href="https://github.com/Frogging-Family">Frogging-Family</a> repositories,
neither more nor less.</strong>

   <a href="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"><img src="https://img.shields.io/badge/version-v0.26.6-brightgreen"></a> <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <a href="https://app.codacy.com/gh/damachine/tkginstaller/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/5736b4b014ca45e1877fc0c75a200c21"></a>

Features
 <strong>- User-friendly interactive control</strong>
 <strong>- Use fast direct terminal commandline mode</strong>
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
