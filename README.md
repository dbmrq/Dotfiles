# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
```

Supports macOS (Intel/Apple Silicon) and Linux. The installer offers two options:

- **Light**: Essential configs only (Vim, Git, Shell) — no cloning required
- **Full**: Complete setup with all configurations — interactive, idempotent, resumable

## Contents

| Directory | Description |
|-----------|-------------|
| `Agents/` | AI agent skills |
| `Bash/` | Bash shell configuration |
| `Bootstrap/` | Setup scripts and CLI tools |
| `Ghostty/` | Ghostty terminal configuration |
| `Git/` | Git configuration and aliases |
| `Hammerspoon/` | macOS window management |
| `Neru/` | Keyboard-driven mouse control (macOS) |
| `Shell/` | Shared shell configuration |
| `SSH/` | SSH configuration |
| `TeX/` | LaTeX configuration |
| `Vim/` | Vim/Neovim configuration |
| `Yazi/` | Yazi file manager configuration |
| `Zellij/` | Zellij terminal multiplexer configuration |
| `Zsh/` | Zsh configuration |
| `macOS/` | macOS-specific configurations |

## Usage

After installation, use the `dotfiles` command:

```sh
dotfiles sync     # Pull latest and re-stow
dotfiles update   # Update everything
dotfiles status   # Check git status
dotfiles edit     # Open dotfiles in editor
```

Individual scripts in `Bootstrap/` can also be run independently (`brew.sh`, `stow.sh`, `prefs.sh`, etc.).
