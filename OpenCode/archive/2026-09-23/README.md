# OpenCode config archive — 2026-09-23

Archived when the global OpenCode config (`~/.config/opencode`) was simplified
back toward a default setup:

- Disabled all custom plugins (`caffeinate`, `task-with-model`,
  `orchestration-context`).
- Removed the custom `abacate` provider and every model pin, so all agents
  inherit the model selected in the UI.
- Kept the custom `orchestrate`, `plan`, and `research` agents and the
  youtube/firecrawl MCP servers (scoped to `research` only).
- Converted `opencode.jsonc` and agent frontmatter to native V2 syntax.

The live config was OpenCode V2 (`v2.0.14`) at the time of archiving. This
directory is excluded from stow via `^/archive` in `.stow-local-ignore`.

## Contents

| Path | Origin | Notes |
| --- | --- | --- |
| `opencode.jsonc.original` | `~/.config/opencode/opencode.jsonc` | Full V1 config: abacate provider, model pins, MCP servers, V1 `permission` map, `subagent_depth`, plugin array |
| `plugin/` | `~/.config/opencode/plugin/` | `caffeinate.ts`, `orchestration/{orchestration-context,task-model,task-with-model}.ts`, package files, `tsconfig.json` |
| `tests/` | `~/.config/opencode/tests/` | Unit tests for the orchestration plugins |
| `commands/subagent-model.md` | `~/.config/opencode/commands/` | Slash command used by the `task-with-model` plugin |
| `package.json`, `package-lock.json` | `~/.config/opencode/` | Root deps for the plugins (`@opencode-ai/plugin`) |
| `docs/agent-orchestration-plan.md` | `~/.config/opencode/` | Historical design/plan document — **local only, gitignored** |
| `docs/orca-setup-plan.md` | `~/.config/opencode/` | Orca setup checklist — **local only, gitignored** (names private repos and homelab details) |
| `dot-config.gitignore` | `~/.config/opencode/.gitignore` | Old ignore list for the (non-git) config dir |

The `docs/` folder is intentionally not tracked: it holds personal notes, so it
is excluded via `OpenCode/archive/*/docs/` in the repo `.gitignore` and stays
on this machine.

`node_modules/` (config root and `plugin/`) was deleted, not archived: it is
reproducible from the archived lockfiles.

## Restoring

The layout mirrors the old `~/.config/opencode/` structure. To restore the
full setup:

1. Move `plugin/`, `tests/`, `commands/`, `package.json`, and
   `package-lock.json` back into `OpenCode/.config/opencode/` in this repo
   (stow links them back into `~/.config/opencode/`).
2. Reinstall dependencies: `npm install` inside `plugin/` and at the config
   root.
3. Re-add the plugin entries to `opencode.jsonc` (native V2 shape):

   ```jsonc
   "plugins": [
     "./plugin/caffeinate.ts",
     "./plugin/orchestration/task-with-model.ts",
     {
       "package": "./plugin/orchestration/orchestration-context.ts",
       "options": {
         "context": {
           "maxContextCharacters": 2000,
           "scopeDepth": 16,
           "retentionMaxRecords": 50,
           "retentionMaxAgeDays": 30
         }
       }
     }
   ]
   ```

   **Important:** these plugins implement the V1 plugin API, which does not run
   on OpenCode V2. They need porting before they work again — see
   <https://opencode.ai/v2/docs/build/plugins/migrate-v1>.
4. Re-add the abacate provider (credentials are still stored under `abacate`
   in `~/.local/share/opencode/auth.json`), in native V2 shape:

   ```jsonc
   "providers": {
     "abacate": {
       "name": "Abacate",
       "package": "@opencode/ai/providers/openai-compatible",
       "settings": { "baseURL": "https://llm.abacate.top/v1" },
       "models": {
         "cost": { "name": "Cost" },
         "balance": { "name": "Balance" },
         "performance": { "name": "Performance" }
       }
     }
   }
   ```

   Then set `"model": "abacate/cost"` globally or per agent to pin models
   again (V1 pins are listed in `opencode.jsonc.original`).

## Not archived here

- Handoff records from the orchestration-context plugin remain in
  `~/.local/share/opencode/agent-orchestration/`. They were left in place and
  deliberately not committed to dotfiles because they may contain sensitive
  captured prompts and tool output.
