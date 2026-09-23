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

The same command-line bootstrap works on Debian/Ubuntu:

```sh
sudo apt-get install -y git curl stow zsh
sudo apt-get install -y \
  $(curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/packages-debian.txt \
     | grep -vE '^\s*#|^\s*$' | tr '\n' ' ')
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
```

OpenCode's config and agents are tracked here and delivered by `stow.sh` (the
retired plugin/orchestration stack is kept under `OpenCode/archive/`). Provider
credentials live in the self-hosted Vaultwarden instance and are synced into
the derived `auth.json` by `vault unlock`:

```sh
vault unlock          # unlocks the vault, regenerates auth.json, loads SSH keys
opencode auth list    # verify the providers
```

Then install the current `opencode` binary if needed:

```sh
curl -fsSL https://opencode.ai/install | bash
```

### Self-hosted Vaultwarden

CLI, SSH, and API credentials live in a self-hosted
[vaultwarden/server](https://github.com/vaultwarden/server) instance, accessed
with the Bitwarden CLI (`bw`). `Bootstrap/vault.sh` installs/points the CLI,
logs in, unlocks, caches the session under `~/.cache/dotfiles/vault/` (0600),
exports the secrets listed in `Bootstrap/vault-env.conf`, regenerates
OpenCode's `auth.json`, and loads the vault SSH keys into the ssh-agent
(Bitwarden desktop agent first, `ssh-add` fallback). The shell exposes it as
`vault` (and `dotfiles vault`):

```sh
vault unlock      # log in/unlock, cache session + env + ssh-agent
vault status      # server, account, lock state
vault get ITEM    # print a secret
vault put ITEM    # store a new secret (stdin/prompt)
vault ssh-load    # refresh the ssh-agent from the vault
vault ssh-upload ~/.ssh/id_ed25519_somekey
vault gh-login    # authenticate gh from the vault token
vault asc-restore # restore ~/.config/app-store-connect
vault lock        # lock and clear cached secrets
```

After unlocking, new shells pick up `BW_SESSION`, the exported credentials,
and the agent socket automatically, so OpenCode, `gh`, `ssh`, and scripts work
without re-entering the master password. See [SECRETS.md](SECRETS.md) for the
full item inventory and new-machine flow.

## Contents

| Directory | Description |
|-----------|-------------|
| `Bash/` | Bash shell configuration |
| `Bootstrap/` | Setup scripts and CLI tools |
| `Ghostty/` | Ghostty terminal configuration |
| `Git/` | Git configuration and aliases |
| `Hammerspoon/` | macOS window management |
| `Neru/` | Keyboard-driven mouse control (macOS) |
| `OpenCode/` | OpenCode CLI config (opencode.jsonc, agents; retired plugin stack under `archive/`) |
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
dotfiles vault    # Vaultwarden credentials (unlock/status/get/...)
```

Individual scripts in `Bootstrap/` can also be run independently (`brew.sh`, `stow.sh`, `prefs.sh`, `vault.sh`, etc.).

## Security

This repo only tracks portable configuration. Machine-specific settings and
credentials live in the self-hosted Vaultwarden instance (see
[SECRETS.md](SECRETS.md)) or in ignored local files. `vault unlock` caches the
session and the exported secrets under `~/.cache/dotfiles/vault/` (mode 0600)
and loads SSH keys into the ssh-agent; OpenCode's `auth.json` is generated from
the vault. No real credential is ever committed — CI runs a secret scan on
every push.
