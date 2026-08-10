# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
```

Supports macOS (Intel/Apple Silicon) and Linux. The installer offers two options:

- **Light**: Essential configs only (Vim, Git, Shell) — no cloning required
- **Full**: Complete setup with all configurations — interactive, idempotent, resumable

## Linux / Debian setup

The same command-line bootstrap works on Debian/Ubuntu with the standard
prereqs installed first:

```sh
sudo apt-get install -y git curl stow zsh
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
```

OpenCode on a new machine needs its config and credentials copied from the
source Mac — never from git:

```sh
scp <mac>:'~/.config/opencode/opencode.jsonc' ~/.config/opencode/opencode.jsonc
scp <mac>:'~/.local/share/opencode/auth.json'  ~/.local/share/opencode/auth.json
chmod 600 ~/.local/share/opencode/auth.json
```

Then install the current `opencode` binary and run a profile check:

```sh
curl -fsSL https://opencode.ai/install | bash
opencode auth list
```

## Contents

| Directory | Description |
|-----------|-------------|
| `Bash/` | Bash shell configuration |
| `Bootstrap/` | Setup scripts and CLI tools |
| `Ghostty/` | Ghostty terminal configuration |
| `Git/` | Git configuration and aliases |
| `Hammerspoon/` | macOS window management |
| `Neru/` | Keyboard-driven mouse control (macOS) |
| `OpenCode/` | OpenCode CLI config (opencode.jsonc, agents, plugin) |
| `Shell/` | Shared shell configuration |
| `SSH/` | SSH configuration |
| `TeX/` | LaTeX configuration |
| `Vim/` | Vim/Neovim configuration |
| `Yazi/` | Yazi file manager configuration |
| `Zed/` | Zed editor settings |
| `Zellij/` | Zellij terminal multiplexer configuration |
| `Zsh/` | Zsh configuration |
| `macOS/` | macOS-specific configurations |

### Agent skills

Personal, external, and Apple Xcode agent skills are **not** tracked here.
The canonical source is the [`dbmrq/agent-skills`](https://github.com/dbmrq/agent-skills)
repo; `Bootstrap/skills.sh` locates it (override with `AGENT_SKILLS_DIR`),
clones it if absent, and runs its `scripts/install-all.sh`, which installs into
real directories such as `~/.agents/skills` and `~/.config/opencode/skills`.
Run `./Bootstrap/skills.sh status` to inspect the current layout.

Seven of the skills are Apple/macOS-only exports (installed via
`xcrun agent skills export`, not CI): `audit-xcode-security-settings`,
`c-bounds-safety`, `device-interaction`, `modernize-tests`, `swiftui-specialist`,
`swiftui-whats-new-27`, and `uikit-app-modernization`. They are intentionally
absent on Linux; the remaining skills install cross-platform.

## Usage

After installation, use the `dotfiles` command:

```sh
dotfiles sync     # Pull latest and re-stow
dotfiles update   # Update everything
dotfiles status   # Check git status
dotfiles edit     # Open dotfiles in editor
```

Individual scripts in `Bootstrap/` can also be run independently (`brew.sh`, `stow.sh`, `prefs.sh`, etc.).

## Security

This repo only tracks portable configuration. Machine-specific settings and
credentials (git identity, GitHub/gh auth, App Store Connect keys, API keys)
live in ignored local files or the macOS keychain. OpenCode provider keys live
only in `~/.local/share/opencode/auth.json` (mode 0600), never in the config.
See [SECRETS.md](SECRETS.md) for what is managed, what is excluded, and how to
recreate a new Mac.
