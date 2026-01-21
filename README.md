# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Light Installation (Any Machine)

For quick setup on temporary or remote machines (works on Linux too):

```sh
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/light.sh | bash
```

This installs only essential configs without cloning the repo:
- **Vim**: Basic settings and key mappings (jk/kj escape, H/L for line start/end, space leader)
- **Git**: Core aliases (co, ci, st, br, tug, sync, lg, etc.)

## Full Installation (Mac)

```sh
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
```

Or manually:

```sh
git clone https://github.com/dbmrq/Dotfiles.git ~/Dotfiles
cd ~/Dotfiles/Bootstrap
./bootstrap.sh
```

The bootstrap script is interactive and asks all questions upfront before running. You can choose which components to install:

- **macOS updates** — Install pending system updates
- **Xcode Command Line Tools** — Required for most development tasks
- **Homebrew** — Package manager with CLI tools and GUI apps
- **macOS preferences** — Dock, Finder, screenshots, etc.
- **Prezto** — Zsh configuration framework
- **Terminal theme** — Solarized color scheme
- **LaTeX** — TeX Live packages and custom classes
- **Battery limiter** — Charge limit tool for battery health
- **Dotfiles** — Symlink configs to home directory

Works on both Intel and Apple Silicon Macs. The script is idempotent and can be safely re-run. If interrupted, it saves progress and offers to resume where it left off.

## Structure

- `Bootstrap/` — Setup scripts for a new Mac
- `Git/` — Git configuration
- `Hammerspoon/` — Window management and automation
- `TeX/` — LaTeX configuration
- `Vim/` — Vim configuration
- `Zsh/` — Shell configuration with Prezto

## Individual Scripts

Each script in `Bootstrap/` can be run independently:

```sh
./brew.sh    # Install Homebrew and packages
./prefs.sh   # Apply macOS preferences
./tlmgr.sh   # Install LaTeX packages
./stow.sh    # Symlink dotfiles
```
