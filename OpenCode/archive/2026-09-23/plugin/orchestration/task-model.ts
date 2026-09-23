/**
 * Pure model-resolution logic for the shadowing `task` tool
 * (see `task-with-model.ts`).
 *
 * This module has no runtime dependencies so it can be unit-tested
 * directly with `node --test`.
 */

/** A `provider/model-id` pair, e.g. `{ providerID: "abacate", modelID: "cost" }`. */
export type ModelRef = {
  providerID: string;
  modelID: string;
};

/**
 * Values for the `model` argument that clear the calling session's sticky
 * default instead of selecting a model. They deliberately contain no `/`,
 * so they can never collide with a real `provider/model-id` value.
 */
export const RESET_SENTINELS: ReadonlySet<string> = new Set(["reset", "pinned", "default"]);

/** Upper bound for sticky entries, so long-lived servers cannot leak memory. */
export const MAX_STICKY_ENTRIES = 200;

export function isResetSentinel(raw: string): boolean {
  return RESET_SENTINELS.has(raw.trim().toLowerCase());
}

/**
 * Parse a `provider/model-id` string. The provider is the segment before the
 * FIRST `/` because model IDs may themselves contain slashes
 * (e.g. `nvidia/meta/llama-3.1-8b-instruct`).
 */
export function parseModelRef(raw: string): ModelRef {
  const trimmed = raw.trim();
  const slash = trimmed.indexOf("/");
  if (slash <= 0 || slash === trimmed.length - 1) {
    throw new Error(
      `Invalid model "${raw}". Expected "provider/model-id" (e.g. "abacate/cost"). ` +
        `Run \`opencode models\` to list available models, or pass "reset" to revert to the pinned model.`,
    );
  }
  return {
    providerID: trimmed.slice(0, slash),
    modelID: trimmed.slice(slash + 1),
  };
}

/**
 * In-memory sticky model defaults, keyed by calling session ID.
 * A new session ID means no entry, which is what makes the default
 * automatically revert to pinned models for the next session.
 * Entries are insertion-ordered so the oldest can be evicted past the cap.
 */
export class StickyModelStore {
  private readonly entries = new Map<string, ModelRef>();
  private readonly maxEntries: number;

  constructor(maxEntries: number = MAX_STICKY_ENTRIES) {
    this.maxEntries = maxEntries;
  }

  get size(): number {
    return this.entries.size;
  }

  get(sessionID: string): ModelRef | undefined {
    return this.entries.get(sessionID);
  }

  set(sessionID: string, model: ModelRef): void {
    // Delete-then-set refreshes insertion order for existing keys.
    this.entries.delete(sessionID);
    this.entries.set(sessionID, model);
    while (this.entries.size > this.maxEntries) {
      const oldest = this.entries.keys().next();
      if (oldest.done) break;
      this.entries.delete(oldest.value);
    }
  }

  clear(sessionID: string): boolean {
    return this.entries.delete(sessionID);
  }

  /** Alias for `clear`, used when a session ends. */
  prune(sessionID: string): void {
    this.entries.delete(sessionID);
  }
}

export type ModelResolution =
  | { kind: "explicit"; model: ModelRef }
  | { kind: "sticky"; model: ModelRef }
  | { kind: "reset"; model: ModelRef | undefined }
  | { kind: "default"; model: ModelRef | undefined };

/**
 * Resolve which model a `task` call should use.
 *
 * Order: explicit `model` argument > calling session's sticky default >
 * agent pin (`agentModel`) > calling session's model (`parentModel`).
 * An explicit value is stored as the new sticky default; a reset sentinel
 * clears it. `requested` must already be normalized (`undefined` when the
 * caller omitted it or passed a blank string).
 */
export function resolveTaskModel(args: {
  requested: string | undefined;
  sticky: StickyModelStore;
  sessionID: string;
  agentModel: ModelRef | undefined;
  parentModel: ModelRef | undefined;
}): ModelResolution {
  const { requested, sticky, sessionID, agentModel, parentModel } = args;
  if (requested !== undefined) {
    if (isResetSentinel(requested)) {
      sticky.clear(sessionID);
      return { kind: "reset", model: agentModel ?? parentModel };
    }
    const parsed = parseModelRef(requested);
    sticky.set(sessionID, parsed);
    return { kind: "explicit", model: parsed };
  }
  const remembered = sticky.get(sessionID);
  if (remembered) return { kind: "sticky", model: remembered };
  return { kind: "default", model: agentModel ?? parentModel };
}

/** Child session title format, identical to the built-in `task` tool. */
export function childSessionTitle(description: string, agentName: string): string {
  return `${description} (@${agentName} subagent)`;
}

/** Max model IDs listed in the `/subagent-model` status output. */
export const MAX_LISTED_MODELS = 60;

export type ProviderLike = {
  id: string;
  models?: Record<string, unknown>;
};

/**
 * Flatten providers to `provider/model-id` strings (model keys sorted per
 * provider for scannability), capped at `limit`. Returns the shown IDs plus
 * the overall total so callers can note truncation.
 */
export function flattenModelIDs(providers: ProviderLike[], limit: number = MAX_LISTED_MODELS): {
  ids: string[];
  total: number;
} {
  const ids: string[] = [];
  let total = 0;
  for (const provider of providers) {
    if (typeof provider?.id !== "string") continue;
    const keys = provider.models ? Object.keys(provider.models).sort() : [];
    total += keys.length;
    for (const key of keys) {
      if (ids.length >= limit) break;
      ids.push(`${provider.id}/${key}`);
    }
    if (ids.length >= limit) break;
  }
  return { ids, total };
}

/** Normalize a slash-command name for comparison (`/SubAgent-Model` -> `subagent-model`). */
export function normalizeCommandName(raw: string): string {
  return raw.trim().replace(/^\//, "").toLowerCase();
}

export type SubagentModelCommandResult = {
  /** Human-readable confirmation/status, sent to the agent as the command result. */
  text: string;
};

/**
 * Pure handler for the `/subagent-model` command. Applies set/clear/status
 * against the calling session's sticky default and returns the text the
 * agent should relay. `requested` is the raw command argument string
 * (empty when the user passed none).
 */
export function handleSubagentModelCommand(args: {
  requested: string;
  sticky: StickyModelStore;
  sessionID: string;
  /** Pre-flattened `provider/model-id` choices for the status output (optional). */
  availableModels?: { ids: string[]; total: number };
}): SubagentModelCommandResult {
  const { requested, sticky, sessionID, availableModels } = args;
  const trimmed = requested.trim();
  if (trimmed === "") {
    const current = sticky.get(sessionID);
    const currentText =
      current === undefined
        ? "(none — each agent's pinned model is in effect)"
        : `${current.providerID}/${current.modelID}`;
    const lines = [
      `Sub-agent model default for this session: ${currentText}.`,
      "",
      "To change it, run `/subagent-model <provider/model-id>` (e.g. `/subagent-model abacate/performance`);",
      "to revert to pinned models, run `/subagent-model reset`.",
    ];
    if (availableModels && availableModels.total > 0) {
      lines.push("", `Available models (${availableModels.total} total):`);
      for (const id of availableModels.ids) lines.push(`- ${id}`);
      if (availableModels.total > availableModels.ids.length) {
        lines.push(`- …and ${availableModels.total - availableModels.ids.length} more (run \`opencode models\`)`);
      }
    } else {
      lines.push("Run `opencode models` or `/models` to browse available models.");
    }
    lines.push("Acknowledge briefly.");
    return { text: lines.join("\n") };
  }
  if (isResetSentinel(trimmed)) {
    sticky.clear(sessionID);
    return {
      text: "Sub-agent model default cleared for this session — agents' pinned models are in effect again. Acknowledge briefly.",
    };
  }
  const parsed = parseModelRef(trimmed);
  sticky.set(sessionID, parsed);
  return {
    text: `Sub-agent model default for this session set to ${parsed.providerID}/${parsed.modelID}. It applies automatically to later task calls that omit a model. Acknowledge briefly.`,
  };
}
