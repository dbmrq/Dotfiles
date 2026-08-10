# Setup & Secret Hygiene

This repository is the single source of truth for **portable** dotfiles and
configuration. Everything here must be safe to push to GitHub and to replay on
a new Mac. Machine-specific settings, credentials, and runtime state are
**intentionally excluded** and recreated per machine.

## What is managed here (tracked)

- Shell (Zsh/Bash), Git, Vim/Neovim, Hammerspoon, Ghostty, Yazi, Zellij,
  TeX, SSH config layout, macOS helpers.
- OpenCode config (`OpenCode/.config/opencode/`): `opencode.jsonc`, `agents/`,
  the `plugin/` code, and the plugin's `package.json`/`package-lock.json`.
- Zed config (`Zed/.config/zed/settings.json`).
- Agent skills are **not** tracked. They come from the canonical
  `dbmrq/agent-skills` repo, installed by `Bootstrap/skills.sh` → its
  `scripts/install-all.sh`. Skill mirrors live in real directories outside this
  repo (`~/.agents/skills`, `~/.config/opencode/skills`, `~/.claude/skills`,
  etc.) and are never committed.

## What is intentionally excluded (never commit)

- `~/.agents`, `~/.claude`, `~/.cursor`, `~/.augment`, `~/.copilot`,
  `~/.config/opencode/skills`, `OpenCode/.config/opencode/skills` — skill
  mirrors and project-local installs.
- `node_modules`, caches, logs, editor history, `~/.local/share/*` runtimes,
  AI sessions.
- Credentials: SSH keys, GPG keys, GitHub tokens, App Store Connect API keys,
  signing certs, API keys, `.env` files, `*.p8`/`*.p12`/`*.pem`/`*.cer`/
  `*.csr`/`*.key`.
- Machine-specific overrides that live **only** on each machine (see below).

## OpenCode provider credentials

OpenCode provider API keys live **only** in `~/.local/share/opencode/auth.json`
(schema: `{ "<provider>": { "type": "api", "key": "…" } }`). The file must stay
mode `0600` and is never committed.

- `~/.local/share/opencode/auth.json` — the sole credential store for OpenCode
  (nvidia, abacate, openrouter, opencode-go, …).
- `OpenCode/.config/opencode/opencode.jsonc` must never contain an inline
  `provider.<name>.options.apiKey`. Config only declares `baseURL`, model IDs,
  agent pins, and plugins; opencode loads the key from `auth.json` at runtime.
- Recreate on a new machine by copying `auth.json` from the source machine
  (`scp` + `chmod 600`), or use `opencode auth login`. Never commit it.
- CI runs a secret scan (patterns such as `sk-*`, inline `apiKey`, private
  keys) to fail any accidental credential commit before it can be pushed.

## Machine-local files (ignored, recreated per machine)

These files are created by the bootstrap or by hand and are **not** tracked:

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | git `user.name`/`user.email`, credential helper, URL rewrites |
| `~/.zshrc.local` | machine shell settings (tool paths, aliases, API keys) |
| `~/.ssh/config.local` | per-machine GitHub host aliases / identity files |
| `~/.config/gh/` | `gh` CLI auth and preferences |
| `~/.config/app-store-connect/` | ASC API credentials + signing material |

See `Git/.gitconfig.local.example` and `Zsh/.zshrc.local.example` for
starting points.

## Recreating a new Mac

1. **Dotfiles**: `curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash`
2. **GitHub CLI auth** (stores the token in the macOS keychain, not on disk as plaintext):
   ```sh
   gh auth login          # choose HTTPS, authenticate via browser
   gh auth setup-git      # wires gh as the git credential helper
   ```
   If you prefer git to always use gh credentials, add to `~/.gitconfig.local`:
   ```ini
   [credential "https://github.com"]
       helper =
       helper = !gh auth git-credential
   [credential "https://gist.github.com"]
       helper =
       helper = !gh auth git-credential
   ```
3. **Git identity** (bootstrap prompts for this; can be done by hand):
   ```ini
   # ~/.gitconfig.local
   [user]
       name = Your Name
       email = you@example.com
   ```
4. **Machine shell config** — create `~/.zshrc.local` (it is sourced by
   `~/.zshrc`). Put tool paths and any API keys here, never in the repo.
5. **Agent skills** — `dotfiles sync` or `Bootstrap/skills.sh install` locates
   the `dbmrq/agent-skills` checkout (override with `AGENT_SKILLS_DIR`), clones
   it if absent, and runs its `scripts/install-all.sh`. Requires `gh` to be
   authenticated.
6. **SSH keys** — generate with `ssh-keygen` and add the public key to the
   relevant GitHub account(s). Private keys never belong in this repo.

## App Store Connect credentials

App Store tooling reads `~/.config/app-store-connect/` (see the
`app-store-connect-analytics` skill). Recreate it on a new Mac from your
password manager, **not** from git:

```sh
mkdir -p ~/.config/app-store-connect
# From your password manager:
cp /path/to/downloaded/AuthKey_XXXXXXXXXX.p8 ~/.config/app-store-connect/
cp /path/to/downloaded/credentials.json ~/.config/app-store-connect/
chmod 600 ~/.config/app-store-connect/*.p8 ~/.config/app-store-connect/credentials.json
```

A safe, redacted template lives at
`Bootstrap/examples/app-store-connect.credentials.json.template`.

## Rules

- Never commit real credentials, tokens, private keys, employer secrets, or
  personal auth data.
- Prefer `.local` overrides (git, shell) for anything machine-specific.
- If a file cannot be made portable safely, keep it out of the repo and
  document how to recreate it instead.
