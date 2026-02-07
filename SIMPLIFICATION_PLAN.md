# Dotfiles Simplification Plan

## Goals
- Simplify the dotfiles setup while maintaining functionality
- Support both macOS and Debian Linux
- Make bootstrap truly idempotent (safe to run multiple times)
- Add CI testing to verify idempotency

---

## Phase 1: Low-Risk Simplifications ✅

### 1.1 Simplify `stow.sh` (~450 → ~145 lines) ✅
- [x] Rewrite using `stow --adopt` + `git checkout` approach
- [x] Remove complex conflict detection logic
- [x] Keep simple verification mode (`--verify`)
- [ ] Add to CI: test stow idempotency (deferred to Phase 6)

### 1.2 Simplify `dotfiles` CLI ✅
- [x] Reduce to single interactive command
- [x] Show menu: sync, edit, status (with short explanations)
- [x] Keep subcommands for scripting (`dotfiles sync`, etc.)

---

## Phase 2: Package Management Overhaul ✅

### 2.1 Replace `features.json` with platform-specific files ✅
- [x] Keep `Brewfile` as single source of truth for macOS
- [x] Create `packages-debian.txt` for Debian/Ubuntu (simple list format)
- [x] Update `lib.sh` to read from appropriate file per platform
- [x] Delete `features.json`

### 2.2 Update package lists ✅
- [x] Use `neovim` only (not vim) on both platforms — keep vim configs for system vim
- [x] Replace `yazi` with `nnn` on both platforms
- [x] Use `zellij` instead of `tmux`
- [x] Add zsh plugins to Brewfile (zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-substring-search)
- [x] Add zoxide to both platforms

---

## Phase 3: Drop Prezto ✅

### 3.1 Identify Prezto features to keep ✅
Current modules used:
- `environment` → inline (5 lines) ✅
- `terminal` → inline (3 lines) ✅
- `editor` → `bindkey -v` + custom vi-mode indicator ✅
- `history` → inline (5 lines) ✅
- `directory` → inline (3 lines) ✅
- `spectrum` → not needed ✅
- `utility` → already in `.shell_common` ✅
- `completion` → `autoload -Uz compinit && compinit` ✅
- `prompt` → move custom prompt to `.zshrc` ✅
- `fasd` → replace with `zoxide` ✅
- `history-substring-search` → install via Homebrew ✅
- `homebrew` → already in `.zprofile` ✅

### 3.2 Create standalone Zsh config ✅
- [x] Move custom prompt (`prompt_dbmrq_setup`) into `.zshrc`
- [x] Add vi-mode indicator without Prezto's `$editor_info` (uses `$VI_MODE_INDICATOR`)
- [x] Add history settings inline
- [x] Add directory options inline
- [x] Add completion setup inline

### 3.3 Add replacement packages ✅
- [x] Add `zsh-syntax-highlighting` to Brewfile and packages-debian.txt
- [x] Add `zsh-autosuggestions` to Brewfile and packages-debian.txt
- [x] Add `zoxide` to Brewfile and packages-debian.txt (replaces fasd)
- [x] Add `zsh-history-substring-search` to Brewfile

### 3.4 Clean up ✅
- [x] Remove `.zpreztorc`
- [x] Remove `.zprezto` directory from Zsh stow package
- [x] Remove Prezto installation from `bootstrap.sh` (made no-op)
- [x] Update `.zshrc` to not source Prezto

---

## Phase 4: Bootstrap Script Overhaul ✓

### 4.1 Remove state management
- [x] Delete `STATE_FILE` logic (~100 lines)
- [x] Delete `save_choices` / `load_choices` functions
- [x] Delete resume prompt logic
- [x] Delete `mark_step_complete` / `step_completed` functions
- [x] Delete `run_step` wrapper function
- [x] Remove all Prezto references

### 4.2 Add detection for already-completed steps
Each step now checks if already done:
- [x] Xcode CLI tools: check `xcode-select -p`
- [x] Homebrew: check `command -v brew`
- [x] CLI packages: check if each is installed
- [x] GUI apps: check if each is installed
- [x] Stow: simplified to just call `stow.sh --force`
- [x] Git identity: check if `.gitconfig.local` has `[user]`
- [x] SSH keys: check if key files exist
- [x] Prezto → removed (see Phase 3)

### 4.3 Make preferences idempotent
- [ ] Check current values before applying
- [ ] Only apply if values differ
- [ ] Skip Dock restart if no changes

### 4.4 Simplify LaTeX handling
- [x] Make LaTeX fully optional (ask explicitly)
- [x] Use BasicTeX only (minimal install)
- [x] Remove complex tlmgr package lists
- [x] Just install what pandoc needs

### 4.5 Ask all questions upfront
- [x] Gather all choices at start (already mostly done)
- [x] Group into logical categories:
  - Essential (always included): Vim, Git, Shell configs
  - CLI tools: ripgrep, fzf, nnn, zoxide, etc.
  - GUI apps (macOS): Hammerspoon, Ghostty, etc.
  - macOS preferences
  - LaTeX (optional)
  - SSH/GitHub setup
- [x] Show summary and confirm before running

---

## Phase 5: Unify Install Script ✓

### 5.1 Simplify `install.sh`
- [x] Remove "light" vs "full" distinction
- [x] Always clone repo (or update if exists)
- [x] Always run `bootstrap.sh`
- [x] Let bootstrap handle the "what to install" questions

### 5.2 Handle root user on Linux
- [x] Keep system package installation for root
- [x] Keep essential config installation for users
- [x] Simplify user selection logic

---

## Phase 6: CI Testing ✓

### 6.1 Create GitHub Actions workflow
- [x] Create `.github/workflows/test-bootstrap.yml`
- [x] Test on macOS runner
- [x] Test on Ubuntu runner

### 6.2 Test idempotency
- [x] Run `stow.sh` twice with --force (dry-run tests bootstrap)
- [x] Verify no errors
- [x] Verify symlinks are correct

### 6.3 Test stow specifically
- [x] Run `stow.sh` on fresh system
- [x] Run `stow.sh` again
- [x] Verify symlinks unchanged
- [x] Verify no conflicts

---

## Files to Create/Modify

### New Files
- [ ] `Bootstrap/packages-debian.txt` — Debian package list
- [ ] `.github/workflows/test-bootstrap.yml` — CI workflow

### Files to Significantly Modify
- [ ] `Bootstrap/stow.sh` — rewrite (~450 → ~50 lines)
- [ ] `Bootstrap/dotfiles` — simplify to interactive menu
- [ ] `Bootstrap/bootstrap.sh` — remove state management, add detection
- [ ] `Bootstrap/install.sh` — remove light/full split
- [ ] `Bootstrap/lib.sh` — update package reading functions
- [ ] `Zsh/.zshrc` — inline Prezto functionality
- [ ] `Bootstrap/Brewfile` — update packages (nnn, zoxide, zsh plugins)

### Files to Delete
- [ ] `Bootstrap/features.json`
- [ ] `Zsh/.zpreztorc`
- [ ] `Zsh/.zprezto/` directory

---

## Package Changes Summary

### Add to Both Platforms
- `nnn` (file manager, replaces yazi)
- `zoxide` (replaces fasd)
- `zellij` (terminal multiplexer)

### Add to macOS Only
- `zsh-syntax-highlighting`
- `zsh-autosuggestions`  
- `zsh-history-substring-search`

### Remove
- `yazi` (replaced by nnn)
- `tmux` (replaced by zellij)
- `vim` / `macvim` (use neovim only, keep configs for system vim)

### Keep vim configs
- `.vimrc`, `.vim/` — still needed for system vim on servers
- Neovim will use its own Lua config

---

## Success Criteria

1. **Simpler**: Net reduction of 500+ lines of shell script
2. **Idempotent**: Running bootstrap twice produces identical results
3. **Tested**: CI passes on both macOS and Ubuntu
4. **Cross-platform**: Works on macOS and Debian
5. **Fast**: Bootstrap completes faster (fewer checks, simpler logic)
6. **Transparent**: Easy to understand what each script does

