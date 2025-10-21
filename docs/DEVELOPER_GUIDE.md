# TKG-Installer Developer Guide

## Overview

The `tkginstaller.sh` script is a modular Bash application for building, installing, and configuring TKG/Frogminer packages from the Frogging-Family repositories. It supports interactive and direct command-line modes, colored output, dependency checks, and configuration management.

---

## Structure

- **tkginstaller.sh**: Main script, contains all logic and functions.
- **update.sh**: Helper script for updating checksums and PKGBUILD metadata.
- **Other files/folders**: Configuration, documentation, and helper scripts.

---

## Main Features

- **Interactive Menu**: Uses `fzf` for a user-friendly selection of actions and packages.
- **Direct Mode**: Allows running specific actions via command-line arguments.
- **Dependency Checks**: Verifies required tools and suggests installation commands.
- **Colored Output**: Uses ANSI colors for info, warning, and error messages.
- **Configuration Management**: Supports editing and downloading config files.
- **Cleanup & Locking**: Prevents concurrent runs and cleans up temporary files.

---

## How the Script Works

1. **Initialization**  
   - Sets up global variables, color codes, and lock files.
   - Detects Linux distribution for package management.

2. **Pre-Checks**  
   - Checks for root execution and warns the user.
   - Verifies required dependencies and suggests install commands if missing.

3. **Modes**  
   - **Interactive**: Runs a menu with `fzf`, allowing the user to select actions.
   - **Direct**: Executes actions based on command-line arguments (e.g. `tkginstaller.sh linux`).

4. **Installation**  
   - Clones the relevant repository.
   - Runs the build/install command appropriate for the detected distribution.
   - Handles errors and displays status messages.

5. **Configuration Editing**  
   - Allows editing config files with the user's preferred editor.
   - Downloads default configs if missing.

6. **Cleanup**  
   - Removes temporary files and lock files on exit.

---

## Adding New Features

1. **Add a New Package/Action**
   - Define a new function for installation (e.g. `__foobar_install()`).
   - Add the package to the menu options in `__menu()`.
   - Add a corresponding prompt function (e.g. `__foobar_prompt()`).
   - Update the case statements in `__main_direct_mode()` and `__main_interactive_mode()`.

2. **Add a New Dependency**
   - Add the dependency to the `_dep` array in `__prepare()`.
   - Map the dependency to its package name in `_pkg_map_dep`.

3. **Add a New Configuration File**
   - Update the config menu options in `__edit_config()`.
   - Add handling logic in `__handle_config()`.

4. **Add a New Message Type**
   - Define a new message function (e.g. `__msg_custom()`).
   - Use the function wherever needed for consistent output.

5. **Change Output Formatting**
   - Edit the color variables in `__init_colors()`.
   - Update message functions for new formatting.

---

## Coding Standards

- Use functions for modularity and readability.
- Always use the provided message functions for output (`__msg_info`, `__msg_warning`, `__msg_error`, etc.).
- Handle errors gracefully and provide clear feedback to the user.
- Keep all new features documented in this guide.

---

## Troubleshooting

- If you encounter issues with dependencies, check the `_dep` and `_pkg_map_dep` arrays.
- For color or Unicode issues, verify your terminal supports UTF-8 and ANSI colors.
- If the script fails to run, check for missing dependencies and permissions.

---

## Contributing

- Fork the repository and create a feature branch.
- Make your changes following the structure and standards above.
- Test your changes in both interactive and direct modes.
- Submit a pull request with a clear description of your changes.

---

## Contact

For questions or suggestions, open an issue on [GitHub](https://github.com/damachine/tkginstaller) or contact the maintainer.
