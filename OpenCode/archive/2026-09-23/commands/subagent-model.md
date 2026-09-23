---
description: Set or show the sub-agent model default for this session
---

The user invoked `/subagent-model` with arguments: "$ARGUMENTS".

Manage the sub-agent model default for this session:

- If a `provider/model-id` was given (e.g. `abacate/performance`): acknowledge it and pass it as `model:` on your next `task` call, which makes it the automatic default for later calls in this session.
- If `reset` was given (or you need to revert): go back to each agent's pinned model.
- If no arguments were given: report the currently effective default and explain how to set it (`/subagent-model <provider/model-id>` or `/subagent-model reset`; `opencode models` lists choices).
