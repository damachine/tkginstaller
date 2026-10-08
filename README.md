
<pre>
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  🐸  ──

<strong>Build &amp; install <a href="https://github.com/Frogging-Family">Frogging-Family</a> stuff with ease</strong>

   <a href="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"><img src="https://img.shields.io/badge/Version-0.60.5-yellow?style=flat&logo=linux"></a> <a href="https://aur.archlinux.org/packages/tkginstaller-git"><img src="https://img.shields.io/aur/version/tkginstaller-git?&logo=arch-linux&label=AUR"></a> <a href="https://github.com/search?q=org%3AFrogging-Family+author%3Adamachine&type=commits"><img src="https://img.shields.io/badge/Frogging--Family-Collaborator-green?style=flat&logo=github"></a>
   
<strong>Features</strong>
 - CLI and fzf menu
 - Configuration editing and diffs
 - Combined Linux-TkG and Nvidia-all installation
 - Build log browser and cache cleanup
</pre>

![TkG-Installer demo](images/demo.gif)

<br />

##### INSTALLATION

```yaml
# Arch Linux-based distributions
# Install via AUR helper (recommended)
yay -S tkginstaller-git
```

```yaml
# All distributions
# Install via automated installation helper
curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | \
  sudo bash
```

<br />

##### USAGE

```yaml
# Use fzf-finder TUI mode, simply run
tkginstaller

# Use direct one-liner CLI mode (skip TUI), run with arguments
tkginstaller [package]
# e.g
tkginstaller linux          # or shortcut
tkginstaller nvidia
tkginstaller linux-nvidia   # or shortcut ln

# Edit a package's configuration file
tkginstaller [config] [package]
# e.g
tkginstaller config         # Enter fzf-finder TUI to select package
tkginstaller config linux   # or shortcut

# Clean up all temporary files
tkginstaller clean

# Show help
tkginstaller help

# To see all available options and shortcuts run:
# h, --help, -h
```

<br />

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
curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | \
  sudo bash -s -- --uninstall

# Or if you have the install.sh downloaded
sudo ./install.sh --uninstall
```

</details>

<br />

###### DISCLAIMER

<pre>
This tool is released under the MIT license.

<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  
Individual TKG/Frogminer packages have their own licenses:
 - See respective repositories at <a href="https://github.com/Frogging-Family">Frogging-Family</a>
</pre>
