# Dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
```

The installer automatically detects your OS (macOS or Linux) and offers two options:

### Light Installation
Essential configs only, no cloning required. Great for temporary or remote machines:
- **Vim**: Basic settings and key mappings (jk/kj escape, H/L for line start/end, space leader)
- **Git**: Core aliases (co, ci, st, br, tug, sync, lg, etc.)
- **Bash** (Linux): Shell aliases and configuration

### Full Installation
Complete setup with all configurations. The bootstrap script is interactive and asks all questions upfront:

**Both platforms:**
- **CLI tools** — Essential command-line utilities
- **Dotfiles** — Symlink configs to home directory
- **Vim/Neovim plugins** — Plugin management

**macOS only:**
- **macOS updates** — Install pending system updates
- **Xcode Command Line Tools** — Required for most development tasks
- **Homebrew** — Package manager with CLI tools and GUI apps
- **macOS preferences** — Dock, Finder, screenshots, etc.
- **Terminal theme** — Solarized color scheme
- **LaTeX** — TeX Live packages and custom classes

Works on both Intel and Apple Silicon Macs. The script is idempotent and can be safely re-run. If interrupted, it saves progress and offers to resume where it left off.

## Structure

| Directory | Platform | Description |
|-----------|----------|-------------|
| `Agents/` | Both | AI agent skills (shared across Augment, Claude Code, etc.) |
| `Bash/` | Linux | Bash shell config, sources `.shell_common` |
| `Bootstrap/` | Both | Setup scripts and CLI tools |
| `Ghostty/` | Both | Ghostty terminal configuration |
| `Git/` | Both | Git configuration and aliases |
| `Hammerspoon/` | macOS | Window management (multi-monitor support) |
| `Shell/` | Both | Shared shell config (`.shell_common`) used by both Bash and Zsh |
| `SSH/` | Both | SSH configuration |
| `TeX/` | macOS | LaTeX configuration |
| `Vim/` | Both | Vim config; Neovim uses Lua with LSP, Treesitter, Telescope |
| `Yazi/` | Both | Yazi file manager configuration |
| `Zellij/` | Both | Zellij terminal multiplexer configuration |
| `Zsh/` | macOS | Zsh configuration (standalone) |

### Shell Configuration

Both Bash and Zsh source `~/.shell_common` for shared settings:
- Common aliases (navigation, safety prompts, git shortcuts)
- PATH configuration
- Editor setup (auto-detects nvim if available)

Platform-specific options are in `.bash_aliases` (Linux) and `.zshrc` (macOS).

## Individual Scripts

Each script in `Bootstrap/` can be run independently:

```sh
./brew.sh        # Interactive Homebrew package installer (select categories)
./prefs.sh       # Apply macOS preferences
./prefs-export.sh # Compare current prefs against expected values
./stow.sh        # Symlink dotfiles
```

### Dotfiles CLI

After installation, the `dotfiles` command is available:

```sh
dotfiles sync     # Pull latest and re-stow
dotfiles update   # Update everything (Homebrew, agent skills, plugins)
dotfiles status   # Check git status
dotfiles edit     # Open dotfiles in editor
dotfiles stow     # Just restow symlinks
dotfiles prefs    # Apply macOS preferences
```
