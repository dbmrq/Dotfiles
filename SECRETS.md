# Setup & Secret Hygiene

This repository is the single source of truth for **portable** dotfiles and
configuration. Everything here must be safe to push to GitHub and to replay on
a new Mac. Machine-specific settings, credentials, and runtime state are
**intentionally excluded** and recreated per machine.

## What is managed here (tracked)

- Shell (Zsh/Bash), Git, Vim/Neovim, Hammerspoon, Ghostty, Yazi, Zellij,
  TeX, SSH config layout, macOS helpers.
- OpenCode config (`OpenCode/.config/opencode/`): `opencode.jsonc` and
  `agents/`. The retired plugin/orchestration stack (code, tests, old config)
  is kept under `OpenCode/archive/`; its `docs/` notes are gitignored and stay
  local.
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

## Credential store: self-hosted Vaultwarden

CLI, SSH, and API credentials live in a self-hosted Vaultwarden instance
(Bitwarden-compatible), accessed through the `bw` CLI:

- **Server**: `https://vault.abacate.top`
- **Account**: `machines@abacate.top`
- **Master password**: macOS keychain (service `vault.abacate.top`, account
  `machines@abacate.top`) or the system keyring on Linux; `vault init` offers
  to store it on a new machine.

`Bootstrap/vault.sh` manages the vault and is exposed as the `vault` shell
function (and `dotfiles vault ...`):

```sh
vault unlock        # log in/unlock, cache session + env vars + ssh-agent
vault status        # server, account, lock state
vault get ITEM      # print a secret (password field by default)
vault env           # refresh exported env vars from vault-env.conf
vault ssh-load      # ensure ssh-agent and load vault SSH keys
vault lock          # lock and clear cached secrets
```

After `vault unlock`, the session (`BW_SESSION`), the exported secrets, and the
ssh-agent socket are cached under `~/.cache/dotfiles/vault/` (mode 0600) and
sourced by `~/.shell_common`, so new shells and the processes they start have
credentials available without re-entering the master password.

### What lives in the vault

| Item | Purpose |
|------|---------|
| `FIRECRAWL_API_KEY` | OpenCode firecrawl MCP |
| `NVIDIA_API_KEY`, `ABACATE_API_KEY`, `OPENROUTER_API_KEY`, `OPENCODE_GO_API_KEY` | OpenCode providers (`auth.json` is generated from these) |
| `GITHUB_TOKEN` | `gh` CLI token; restore with `vault gh-login` |
| `EQ12` | SSH/SMB login for the homelab mini PC (`eq12.local` / `10.0.0.10`) |
| `SSH_KEY_*` | SSH key pairs (type 5) loaded into the ssh-agent by `vault ssh-load` |
| `APPSTORE_CONNECT` | App Store Connect `credentials.json` + `AuthKey_*.p8`; restore with `vault asc-restore` |
| `CLOUDFLARE_*`, `DOCKERHUB_*`, `LITELLM_*`, `WUD_*` | Homelab service credentials |

Add new credentials from the repo itself:

```sh
printf '%s' "$SECRET" | vault put MY_ITEM --username user --notes "what it is"
vault ssh-upload ~/.ssh/id_ed25519_something   # stores the key pair in the vault
```

Then add a line to `Bootstrap/vault-env.conf` (`ENV_VAR=ITEM_NAME`) if the
value should be exported to the environment.

### Environment variables

`Bootstrap/vault-env.conf` maps environment variables to vault items. `vault
unlock` / `vault env` write them to `~/.cache/dotfiles/vault/env` (0600) and
`~/.shell_common` sources that file while a session is active. Never commit a
real value here — the file only contains item names.

### SSH agent

`vault ssh-load` prefers the Bitwarden desktop SSH agent when it is running,
unlocked, and exposes the vault keys (macOS socket under
`~/Library/Group Containers/LTZ2PFU5D6.com.bitwarden.desktop/s.bw`). Otherwise
it ensures a system `ssh-agent` and loads the `SSH_KEY_*` items with
`ssh-add -` (keys live only in agent memory). The chosen socket is cached in
`~/.cache/dotfiles/vault/agent`.

To use the desktop agent, add the `machines@abacate.top` account in the
Bitwarden desktop app, unlock it, and enable its SSH agent setting; `vault
ssh-load` picks the socket automatically once the vault keys are visible
through it.

The shared `SSH_KEY_HOMELAB` key grants access to `daniel@eq12.local` (see
`SSH/.ssh/config`). New machines only need `vault unlock && vault ssh-load`.

### OpenCode provider credentials

OpenCode provider API keys are generated from the vault by `vault
sync-opencode` (run automatically by `vault unlock`). The vault is the source
of truth; `~/.local/share/opencode/auth.json` is a derived file:

- `~/.local/share/opencode/auth.json` — generated (mode 0600), never committed.
- `OpenCode/.config/opencode/opencode.jsonc` must never contain an inline
  API key. The config only declares MCP servers, permissions, and agent
  definitions.
- On a new machine, `vault unlock` regenerates `auth.json`; there is no need to
  `scp` it around anymore.
- CI runs a secret scan (patterns such as `sk-*`, inline `apiKey`, private
  keys) to fail any accidental credential commit before it can be pushed.

### App Store Connect credentials

`vault asc-restore` writes `~/.config/app-store-connect/credentials.json` and
the referenced `AuthKey_*.p8` (mode 0600) from the `APPSTORE_CONNECT` vault
item. `vault asc-upload` refreshes the vault item from the local files. The
signing certs under `certs/` remain machine-local.

## Machine-local files (ignored, recreated per machine)

These files are created by the bootstrap or by hand and are **not** tracked:

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | git `user.name`/`user.email`, credential helper, URL rewrites |
| `~/.zshrc.local` | machine shell settings (tool paths, aliases, non-vault overrides) |
| `~/.ssh/config.local` | per-machine GitHub host aliases / identity files |
| `~/.config/gh/` | `gh` CLI auth and preferences (optional; `GH_TOKEN` comes from the vault) |
| `~/.config/app-store-connect/` | ASC API credentials + signing material (restorable with `vault asc-restore`) |
| `~/.cache/dotfiles/vault/` | vault session/env/agent cache, mode 0600 (created by `vault unlock`) |

See `Git/.gitconfig.local.example` and `Zsh/.zshrc.local.example` for
starting points.

## Recreating a new Mac

1. **Dotfiles**: `curl -fsSL https://raw.githubusercontent.com/dbmrq/Dotfiles/master/Bootstrap/install.sh | bash`
2. **Vaultwarden**: choose the Vaultwarden step in the bootstrap (or run
   `vault init` later). It installs the `bw` CLI, points it at
   `https://vault.abacate.top`, logs in as `machines@abacate.top`, unlocks,
   caches the session/env/agent files, regenerates OpenCode's `auth.json`, and
   loads the vault SSH keys into the agent. The master password is read from
   the keychain/keyring or prompted (and can be stored during `init`).
3. **GitHub CLI auth**: comes from the vault (`GH_TOKEN` after `vault unlock`);
   to wire the keyring explicitly:
   ```sh
   vault gh-login          # gh auth login --with-token using GITHUB_TOKEN
   gh auth setup-git       # wires gh as the git credential helper
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
4. **Git identity** (bootstrap prompts for this; can be done by hand):
   ```ini
   # ~/.gitconfig.local
   [user]
       name = Your Name
       email = you@example.com
   ```
5. **Machine shell config** — create `~/.zshrc.local` (it is sourced by
   `~/.zshrc`) for tool paths and machine-specific settings. Credentials belong
   in the vault, not here.
6. **Agent skills** — `dotfiles sync` or `Bootstrap/skills.sh install` locates
   the `dbmrq/agent-skills` checkout (override with `AGENT_SKILLS_DIR`), clones
   it if absent, and runs its `scripts/install-all.sh`. Requires `gh` to be
   authenticated (`vault unlock` provides `GH_TOKEN`).
7. **SSH keys** — the shared `SSH_KEY_HOMELAB` key comes from the vault:
   `vault unlock && vault ssh-load`. Keys for GitHub accounts can be stored
   with `vault ssh-upload` and loaded the same way; private keys never belong
   in this repo.
8. **App Store Connect** — `vault asc-restore` recreates
   `~/.config/app-store-connect/` (a safe, redacted template lives at
   `Bootstrap/examples/app-store-connect.credentials.json.template`). The
   signing certs under `certs/` are still recreated from Apple tooling.

## Rules

- Never commit real credentials, tokens, private keys, employer secrets, or
  personal auth data.
- Prefer `.local` overrides (git, shell) for anything machine-specific.
- If a file cannot be made portable safely, keep it out of the repo and
  document how to recreate it instead.
