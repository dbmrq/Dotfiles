# Debian / Ubuntu setup

Copy-pasteable walkthrough for bringing a fresh Debian (or Ubuntu, Linux
Mint, Pop!_OS) machine up to the same dotfiles + OpenCode setup as the source
Mac. Everything here is CLI-focused; GUI apps and macOS-only steps are skipped
automatically.

## 1. System prerequisites

```sh
sudo apt-get update
sudo apt-get install -y git curl stow zsh
# Remaining CLI tools from the repo manifest (ripgrep, fzf, eza, zellij, ...):
sudo apt-get install -y \
  $(curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/packages-debian.txt \
     | grep -vE '^\s*#|^\s*$' | tr '\n' ' ')
```

Note: Ubuntu/Debian ship `stow` 2.3.1. `Bootstrap/stow.sh` deliberately never
combines `--adopt` with `--restow` on the same invocation, so the known 2.3.1
unstow bug (fixed in 2.4.0) cannot trigger on a fresh bootstrap. CI builds a
pinned 2.4.x instead; the mac's Homebrew stow is already 2.4.1.

## 2. Install the dotfiles

Option A — one-shot installer (interactive; needs a TTY). It clones into
`~/Dotfiles` and runs `Bootstrap/bootstrap.sh`:

```sh
curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash
```

For a non-interactive run afterwards:

```sh
cd ~/Dotfiles/Bootstrap && ./bootstrap.sh --force
```

Option B — explicit clone + stow (declarative, easiest to inspect):

```sh
git clone https://github.com/dbmrq/Dotfiles.git ~/Dotfiles
cd ~/Dotfiles
./Bootstrap/stow.sh --force
```

What `stow.sh --force` does:

- Symlinks every tracked package into `$HOME` (`.zshrc`, `.vimrc`,
  `.gitconfig`, `~/.config/opencode/…`, `~/.config/zed/settings.json`, …).
- Pre-creates real `~/.config/opencode` and `~/.config/zed` directories first,
  so those directories are **never** folded into repo-wide symlinks (runtime
  state such as skills stays outside the repo).
- Skips macOS-only packages: `Hammerspoon/`, `TeX/`, `macOS/`, and macOS Quick
  Actions. `Neru/` is stowed but inert without the macOS app. `SSH/` stows the
  portable config layout; per-machine `config.local` stays untracked.
- Refuses to run over uncommitted working-tree changes (safety guard), so
  anything the install adopts is reset repo-scoped, never `git checkout .`.

Agent skills come from the canonical `dbmrq/agent-skills` repo, not from git:

```sh
./Bootstrap/skills.sh install
```

Requires `gh auth login` (the installer refreshes the checkout via git and
runs `install-all.sh`). Override the checkout location with
`AGENT_SKILLS_DIR=/path/to/agent-skills`.

## 3. Install the current opencode binary

```sh
curl -fsSL https://opencode.ai/install | bash
```

Or via a package manager (documented fallback):

```sh
npm install -g opencode-ai
# or: bun add -g opencode-ai
```

Verify with `opencode --version`.

## 4. Credentials — no re-login required

The OpenCode config is tracked in this repo and lands in `~/.config/opencode`
via stow. Provider API keys live **only** in `~/.local/share/opencode/auth.json`
and must be copied from the source Mac, never fetched from git:

```sh
mkdir -p ~/.local/share/opencode
scp <mac>:'~/.local/share/opencode/auth.json' ~/.local/share/opencode/auth.json
chmod 600 ~/.local/share/opencode/auth.json
opencode auth list   # abacate, nvidia, openrouter, opencode-go
```

Optional git identity (or copy `~/.gitconfig.local` from the Mac):

```sh
gh auth login
gh auth setup-git
```

## 5. First-run expectations

**Will work:**
- `opencode` defaults to `abacate/cost`; subagents `build`/`general`/`explore`
  are pinned to it; `orchestrate`/`plan` are unpinned and follow the session
  model (switchable via the TUI model picker).
- The orchestration plugin (`plugin/orchestration/orchestration-context.ts`,
  plus its test file) persists cross-session agent context.
- `switch-models.sh free|paid` swaps profile pins. The free profile targets
  `opencode/deepseek-v4-flash-free`, so it needs the opencode provider key in
  `auth.json`.
- Cross-platform agent skills install via `skills.sh` into real directories
  (`~/.agents/skills`, `~/.config/opencode/skills`, …).

**Skipped / no-op on Linux:**
- `plugin/caffeinate.ts` returns an empty plugin when `process.platform` is not
  `darwin` — no-op.
- The seven Apple/macOS-only skills (`audit-xcode-security-settings`,
  `c-bounds-safety`, `device-interaction`, `modernize-tests`,
  `swiftui-specialist`, `swiftui-whats-new-27`, `uikit-app-modernization`)
  are intentionally absent on Linux; the remaining skills install cross-platform.
- macOS-only packages (Hammerspoon, TeX, Homebrew casks), `prefs.sh`,
  `brew.sh`, and Quick Actions are skipped or no-op.

## 6. Optional: self-host VaultWarden

Pair this dotfiles setup with a self-hosted, Bitwarden-compatible password
manager ([vaultwarden/server](https://github.com/vaultwarden/server)) on the
same Debian box:

```sh
docker run -d --name vaultwarden \
  -e DOMAIN=https://vault.example.com \
  -e SIGNUPS_ALLOWED=false \
  -v /vw-data/:/data/ \
  -p 8080:80 \
  vaultwarden/server:latest
```

See the project README for TLS via the bundled `bitwarden_rs` wildcard
certificates or reverse-proxy setup. Store `BW_CLIENTID`/`BW_CLIENTSECRET` /
`BW_PASSWORD` etc. in `~/.zshrc.local`, which is machine-local and never
tracked (see [SECRETS.md](SECRETS.md)).