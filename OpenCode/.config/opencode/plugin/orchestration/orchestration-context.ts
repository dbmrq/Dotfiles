import { mkdir, readFile, readdir, rename, rm, stat, writeFile } from "node:fs/promises";
import { randomBytes } from "node:crypto";
import { dirname, join } from "node:path";
import type { Hooks, Plugin } from "@opencode-ai/plugin";

const PLUGIN_ID = "orchestration-context";

export const DEFAULT_STORAGE_ROOT = join(
  process.env.HOME ?? "/tmp",
  ".local",
  "share",
  "opencode",
  "agent-orchestration",
);

const DEFAULT_OPTIONS = {
  maxContextCharacters: 2_000,
  scopeDepth: 16,
  retentionMaxRecords: 50,
  retentionMaxAgeDays: 30,
} as const;

export type ContextOptions = {
  maxContextCharacters?: number;
  storageRoot?: string;
  retentionMaxRecords?: number;
  retentionMaxAgeDays?: number;
};

export type PluginTupleOptions = {
  context?: ContextOptions;
};

export type HandoffStatus = "completed" | "failed";

export type HandoffMetadata = {
  id: string;
  sessionID: string;
  rootSessionID: string;
  parentSessionID: string;
  projectID: string;
  agent: string;
  status: HandoffStatus;
  error?: string;
  model?: { providerID: string; modelID: string };
  created: string;
  updated: string;
  completed: string;
  result: string;
  summary: string;
  taskPrompt?: string;
  systemContext?: string;
  files: string[];
  sections: {
    summary?: string;
    changes?: string;
    files?: string;
    verification?: string;
    risks?: string;
    blockers?: string;
    handoff?: string;
  };
  resultPath: string;
};

export type SessionInfo = { parentID?: string; projectID?: string };

export type ParsedOptions = {
  context: {
    maxContextCharacters: number;
    scopeDepth: number;
    storageRoot: string;
    retentionMaxRecords: number;
    retentionMaxAgeDays: number;
  };
  warnings: string[];
};

const isPlainObject = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);

const positiveNumber = (value: unknown, fallback: number, warnings: string[], label: string) => {
  if (value === undefined) return fallback;
  if (typeof value !== "number" || !Number.isFinite(value) || !Number.isInteger(value) || value <= 0) {
    warnings.push(`invalid ${label}, using default ${fallback}`);
    return fallback;
  }
  return value;
};

/**
 * Like `positiveNumber` but allows 0 (e.g. `retentionMaxAgeDays: 0` disables
 * age-based pruning).
 */
const nonNegativeNumber = (value: unknown, fallback: number, warnings: string[], label: string) => {
  if (value === undefined) return fallback;
  if (typeof value !== "number" || !Number.isFinite(value) || !Number.isInteger(value) || value < 0) {
    warnings.push(`invalid ${label}, using default ${fallback}`);
    return fallback;
  }
  return value;
};

/**
 * Parse the plugin tuple options. Unknown top-level keys are rejected (ignored
 * with a warning), never blindly forwarded, and no unexpected top-level config
 * keys are introduced. Invalid/missing values fall back to typed defaults.
 */
export function parseContextOptions(raw: unknown, envOpenCodeContextDir = process.env.OPENCODE_CONTEXT_DIR): ParsedOptions {
  const warnings: string[] = [];
  const ctx: Record<string, unknown> = {};
  const context = DEFAULT_OPTIONS;

  if (raw !== undefined && raw !== null) {
    if (!isPlainObject(raw)) {
      warnings.push("plugin options must be an object; using defaults");
    } else {
      for (const key of Object.keys(raw)) {
        if (key !== "context") warnings.push(`unknown top-level option key "${key}" ignored`);
      }
      const provided = raw["context"];
      if (provided !== undefined) {
        if (isPlainObject(provided)) Object.assign(ctx, provided);
        else warnings.push("options.context must be an object; using defaults");
      }
    }
  }

  const fall = (label: string, fallback: number) => positiveNumber(ctx[label], fallback, warnings, `context.${label}`);

  let maxContextCharacters = fall("maxContextCharacters", context.maxContextCharacters);
  if (ctx["maxContextCharacters"] !== undefined && maxContextCharacters < 200) {
    warnings.push("context.maxContextCharacters too small; using 200");
    maxContextCharacters = 200;
  }

  const storageRoot =
    typeof ctx["storageRoot"] === "string" && ctx["storageRoot"].length > 0
      ? ctx["storageRoot"]
      : envOpenCodeContextDir ?? DEFAULT_STORAGE_ROOT;

  return {
    context: {
      maxContextCharacters,
      scopeDepth: fall("scopeDepth", context.scopeDepth),
      storageRoot,
      retentionMaxRecords: fall("retentionMaxRecords", context.retentionMaxRecords),
      retentionMaxAgeDays: nonNegativeNumber(ctx["retentionMaxAgeDays"], context.retentionMaxAgeDays, warnings, "context.retentionMaxAgeDays"),
    },
    warnings,
  };
}

export const safeSegment = (value: string) => value.replace(/[^a-zA-Z0-9._-]/g, "_");

export const truncate = (text: string, limit: number) => {
  const suffix = "\n...[truncated]";
  if (text.length <= limit) return text;
  return `${text.slice(0, Math.max(0, limit - suffix.length))}${suffix}`;
};

const textFromPart = (part: unknown): string | undefined => {
  if (
    typeof part === "object" &&
    part !== null &&
    (part as { type?: unknown }).type === "text" &&
    typeof (part as { text?: unknown }).text === "string"
  ) {
    return (part as { text: string }).text;
  }
  return undefined;
};

export const textFromParts = (parts: unknown): string =>
  Array.isArray(parts)
    ? parts
        .map(textFromPart)
        .filter((t): t is string => t !== undefined)
        .join("\n\n")
        .trim()
    : "";

type SectionKey = keyof NonNullable<HandoffMetadata["sections"]>;

const HEADING_OF = new Map<SectionKey, RegExp>([
  ["summary", /^#{1,3}\s*summary\s*$/im],
  ["changes", /^#{1,3}\s*changes?\s*$/im],
  ["files", /^#{1,3}\s*(files?|changed?\s*files)\s*$/im],
  ["verification", /^#{1,3}\s*verification\s*$/im],
  ["risks", /^#{1,3}\s*(risks?|risks?\s*or\s*blockers?)\s*$/im],
  ["blockers", /^#{1,3}\s*(blockers?|blocking|blocked)\s*$/im],
  ["handoff", /^#{1,3}\s*handoff\s*$/im],
]);

/**
 * Deterministically extract top-level markdown sections from a result so the
 * stored metadata carries structured summary/files/verification/risks/blockers
 * without relying on model agreement on headings.
 */
export function extractSections(text: string, max: number = 800): NonNullable<HandoffMetadata["sections"]> {
  const sections: NonNullable<HandoffMetadata["sections"]> = {};
  const lines = text.split("\n");
  let current: SectionKey | null = null;
  const buffer: string[] = [];
  const flush = () => {
    if (current) {
      const body = buffer.join("\n").trim();
      if (body) (sections as Record<string, string>)[current] = truncate(body, max);
    }
  };
  for (const line of lines) {
    let matched: SectionKey | null = null;
    for (const [key, re] of HEADING_OF) {
      if (re.test(line)) {
        matched = key;
        break;
      }
    }
    if (matched) {
      flush();
      current = matched;
      buffer.length = 0;
    } else {
      buffer.push(line);
    }
  }
  flush();
  return sections;
}

const extractIntents = (text: string): string[] => {
  const intents: string[] = [];
  const re = /^\s*[-*]\s*\[?x?\]?\s*(.{2,120})$/gim;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text)) !== null && intents.length < 20) {
    const line = m[1].trim();
    if (line && !/https?:\/\//i.test(line)) intents.push(line);
  }
  return intents;
};

export async function atomicWrite(filePath: string, content: string): Promise<void> {
  const tmp = `${filePath}.tmp-${process.pid}-${randomBytes(6).toString("hex")}`;
  // Records (including captured prompts/system context) may contain sensitive
  // project content, so create dirs and files with restrictive permissions.
  await mkdir(dirname(filePath), { recursive: true, mode: 0o700 });
  await writeFile(tmp, content, { encoding: "utf8", mode: 0o600 });
  try {
    await rename(tmp, filePath);
  } catch (err) {
    await rm(tmp, { force: true }).catch(() => undefined);
    throw err;
  }
}

export type Scope = { rootSessionID: string; projectID: string };

type MessageLike = {
  info?: {
    role?: string;
    id?: string;
    sessionID?: string;
    agent?: string;
    mode?: string;
    providerID?: string;
    modelID?: string;
    error?: { name?: string } | null;
    time?: { created?: number };
  };
  parts?: unknown[];
};

export type HandoffStoreOptions = {
  storageRoot: string;
  projectID: string;
  scopeDepth: number;
  /** Max records kept per scope. Default 50. */
  retentionMaxRecords?: number;
  /** Delete records older than this many days (0 disables age pruning). Default 30. */
  retentionMaxAgeDays?: number;
  resolver: {
    getSession(sessionID: string): Promise<SessionInfo | undefined>;
    getMessages(sessionID: string): Promise<MessageLike[]>;
  };
  log?(level: "info" | "warn" | "error", message: string): void | Promise<void>;
};

const lastAssistant = (messages: MessageLike[]) => {
  for (let i = messages.length - 1; i >= 0; i--) {
    const m = messages[i];
    if (m?.info?.role === "assistant") return m;
  }
  return undefined;
};

const lastUser = (messages: MessageLike[]) => {
  for (let i = messages.length - 1; i >= 0; i--) {
    const m = messages[i];
    if (m?.info?.role === "user") return m;
  }
  return undefined;
};

const resolveAgent = (messages: MessageLike[]): string => {
  const user = lastUser(messages);
  if (user?.info?.agent) return user.info.agent;
  const assistant = lastAssistant(messages);
  if (assistant?.info?.mode) return assistant.info.mode;
  return "subagent";
};

/**
 * Project- and root-session-scoped handoff store. Records are written per
 * child session as atomic temp-file-then-rename JSON/Markdown pairs inside a
 * `records/` directory. The manifest is always rebuilt by listing record
 * files; there is no shared mutable index that could be clobbered by
 * concurrent children.
 */
export class HandoffStore {
  readonly options: HandoffStoreOptions;
  private readonly known = new Map<string, SessionInfo>();
  private readonly persisting = new Set<string>();
  private readonly persisted = new Set<string>();
  private childrenDirty = true;
  private activeByRoot = new Map<string, string[]>();

  constructor(options: HandoffStoreOptions) {
    this.options = {
      ...options,
      retentionMaxRecords: options.retentionMaxRecords ?? 50,
      retentionMaxAgeDays: options.retentionMaxAgeDays ?? 30,
    };
  }

  async log(level: "info" | "warn" | "error", message: string) {
    if (this.options.log) {
      try {
        await this.options.log(level, message);
      } catch {
        // best-effort
      }
    }
  }

  remember(info: { id: string; parentID?: string; projectID?: string }) {
    this.known.set(info.id, { parentID: info.parentID, projectID: info.projectID });
    this.childrenDirty = true;
  }

  async getSession(sessionID: string): Promise<SessionInfo | undefined> {
    const known = this.known.get(sessionID);
    if (known && (known.parentID !== undefined || known.projectID !== undefined)) return known;
    try {
      const info = await this.options.resolver.getSession(sessionID);
      if (info) {
        this.known.set(sessionID, info);
        this.childrenDirty = true;
        return info;
      }
    } catch {
      // fall through to known info
    }
    return known && (known.parentID !== undefined || known.projectID !== undefined) ? known : undefined;
  }

  /**
   * Walk the parent chain (bounded by scopeDepth) to the root session and
   * resolve the project it belongs to.
   */
  async resolveRootProject(sessionID: string): Promise<Scope | undefined> {
    let current: string | undefined = sessionID;
    let info = await this.getSession(current);
    let depth = 0;
    while (info && info.parentID && depth < this.options.scopeDepth) {
      current = info.parentID;
      info = await this.getSession(current);
      depth++;
    }
    if (!info || current === undefined) return undefined;
    return { rootSessionID: current, projectID: info.projectID ?? this.options.projectID };
  }

  storeDir(scope: Scope): string {
    return join(
      this.options.storageRoot,
      safeSegment(scope.projectID),
      safeSegment(scope.rootSessionID),
      "records",
    );
  }

  private async refreshActive(scope: Scope): Promise<void> {
    const ids: string[] = [];
    for (const [sid, info] of this.known) {
      if (!info.parentID) continue;
      const r = await this.resolveRootProject(sid);
      if (r && r.rootSessionID === scope.rootSessionID && r.projectID === scope.projectID) {
        ids.push(sid);
        if (ids.length >= 32) break;
      }
    }
    ids.sort();
    this.activeByRoot.set(scope.rootSessionID, ids);
    this.childrenDirty = false;
  }

  async activeChildIDs(scope: Scope, max: number = 20): Promise<string[]> {
    if (this.childrenDirty) await this.refreshActive(scope);
    return (this.activeByRoot.get(scope.rootSessionID) ?? []).slice(0, max);
  }

  async persist(sessionID: string, extra?: { systemContext?: string }): Promise<boolean> {
    if (this.persisted.has(sessionID) || this.persisting.has(sessionID)) return false;
    this.persisting.add(sessionID);
    try {
      const info = await this.getSession(sessionID);
      if (!info?.parentID) return false;
      const scope = await this.resolveRootProject(sessionID);
      if (!scope) return false;

      let messages: MessageLike[] = [];
      try {
        messages = await this.options.resolver.getMessages(sessionID);
      } catch (err) {
        await this.log("error", `messages fetch failed for ${sessionID}: ${(err as Error).message}`);
        return false;
      }

      const assistant = lastAssistant(messages);
      if (!assistant?.info) return false;

      const result =
        textFromParts(assistant.parts) || "The agent completed without a textual final report.";
      if (!Array.isArray(assistant.parts)) return false;

      const sections = extractSections(result);
      // Task prompt = last user message text (the actual ask the sub-agent received).
      const user = lastUser(messages);
      const taskPrompt = (user ? textFromParts(user.parts) : "") || "(no task prompt captured)";
      const created =
        typeof assistant.info.time?.created === "number"
          ? new Date(assistant.info.time.created).toISOString()
          : new Date().toISOString();
      const completed = new Date().toISOString();
      const status: HandoffStatus = assistant.info.error ? "failed" : "completed";
      const model =
        typeof assistant.info.providerID === "string" && typeof assistant.info.modelID === "string"
          ? { providerID: assistant.info.providerID, modelID: assistant.info.modelID }
          : undefined;
      const summary = truncate(sections.summary ?? result, 240);
      const safeFile = safeSegment(sessionID);
      const dir = this.storeDir(scope);
      const resultPath = join(dir, `${safeFile}.md`);
      const metaPath = join(dir, `${safeFile}.json`);
      const base = {
        id: sessionID,
        sessionID,
        rootSessionID: scope.rootSessionID,
        parentSessionID: info.parentID ?? "",
        projectID: scope.projectID,
        agent: resolveAgent(messages),
        status,
        error: assistant.info.error?.name,
        model,
        created,
        updated: completed,
        completed,
        result: truncate(result, 12_000),
        summary,
        taskPrompt: truncate(taskPrompt, 12_000),
        systemContext: extra?.systemContext ? truncate(extra.systemContext, 12_000) : undefined,
        files: extractIntents(sections.files ?? ""),
        sections,
        resultPath,
      };

      await atomicWrite(metaPath, `${JSON.stringify(base, null, 2)}\n`);
      await atomicWrite(resultPath, this.buildMarkdown(base));

      // Enforce retention limits so a scope never exceeds its budget.
      await this.prune(scope);

      await this.log("info", `persisted handoff ${sessionID} (${status}) for root ${scope.rootSessionID}`);
      this.persisted.add(sessionID);
      return true;
    } catch (err) {
      await this.log("error", `handoff persist failed for ${sessionID}: ${(err as Error).message}`);
      return false;
    } finally {
      this.persisting.delete(sessionID);
    }
  }

  private buildMarkdown(meta: HandoffMetadata): string {
    const lines = [
      `# Agent Result: ${meta.agent}`,
      "",
      `- Handoff ID: ${meta.id}`,
      `- Root session: ${meta.rootSessionID}`,
      `- Parent session: ${meta.parentSessionID}`,
      `- Project: ${meta.projectID}`,
      `- Status: ${meta.status}`,
      meta.model ? `- Model: ${meta.model.providerID}/${meta.model.modelID}` : null,
      `- Completed: ${meta.completed}`,
      "",
      "## Task Prompt",
      "",
      meta.taskPrompt ?? "(not captured)",
      "",
      "## System Context",
      "",
      meta.systemContext ?? "(not captured)",
      "",
      "## Result",
      "",
      meta.result,
      "",
    ];
    lines.push("");
    return lines.filter((l): l is string => l !== null).join("\n");
  }

  /**
   * Read all persisted metadata entries from disk for a given scope.
   */
  private async entries(scope: Scope): Promise<HandoffMetadata[]> {
    const dir = this.storeDir(scope);
    let files: string[];
    try {
      files = await readdir(dir);
    } catch {
      return [];
    }
    const metas: HandoffMetadata[] = [];
    for (const file of files) {
      if (!file.endsWith(".json")) continue;
      try {
        const raw = await readFile(join(dir, file), "utf8");
        const meta = JSON.parse(raw) as HandoffMetadata;
        if (meta && typeof meta.id === "string") metas.push(meta);
      } catch {
        // skip corrupt/partial record
      }
    }
    metas.sort((a, b) => b.completed.localeCompare(a.completed));
    return metas;
  }

  /**
   * Enforce retention limits for a scope: delete records older than
   * `retentionMaxAgeDays` (if > 0) and, if more than `retentionMaxRecords`
   * remain, delete the oldest ones (by `completed`) beyond the cap. Returns
   * the number of records deleted.
   */
  async prune(scope: Scope): Promise<number> {
    const records = await this.entries(scope);
    if (records.length === 0) return 0;

    const maxAgeDays = this.options.retentionMaxAgeDays ?? 30;
    const maxRecords = this.options.retentionMaxRecords ?? 50;

    const toDelete = new Set<string>();
    let remaining: HandoffMetadata[] = records;

    // (a) Age-based pruning. Unparseable completion dates are kept.
    if (maxAgeDays > 0) {
      const cutoff = Date.now() - maxAgeDays * 86_400_000;
      remaining = [];
      for (const r of records) {
        const t = Date.parse(r.completed);
        if (Number.isNaN(t)) {
          remaining.push(r);
        } else if (t < cutoff) {
          toDelete.add(r.id);
        } else {
          remaining.push(r);
        }
      }
    }

    // (b) Count-based pruning. `remaining` is sorted newest-first, so the
    // tail beyond the limit holds the oldest records.
    if (remaining.length > maxRecords) {
      for (const r of remaining.slice(maxRecords)) {
        toDelete.add(r.id);
      }
      remaining = remaining.slice(0, maxRecords);
    }

    if (toDelete.size === 0) return 0;

    const dir = this.storeDir(scope);
    let deleted = 0;
    for (const r of records) {
      if (!toDelete.has(r.id)) continue;
      const resultPath = r.resultPath;
      const metaPath = resultPath.endsWith(".md")
        ? `${resultPath.slice(0, -3)}.json`
        : join(dir, `${safeSegment(r.id)}.json`);
      // Remove both the `.md` and sibling `.json` file; a single failure must
      // not abort the sweep.
      let ok = true;
      try {
        await rm(resultPath, { force: true });
      } catch {
        ok = false;
      }
      try {
        await rm(metaPath, { force: true });
      } catch {
        ok = false;
      }
      if (ok) deleted++;
    }

    if (deleted > 0) {
      await this.log("info", `pruned ${deleted} records from ${scope.rootSessionID}`);
    }
    return deleted;
  }

  /**
   * Enforce retention limits across every project/root-session scope under
   * the storage root. Non-directories and read errors are ignored silently.
   * Returns the total number of records deleted.
   */
  async sweepAll(): Promise<number> {
    let total = 0;
    let projects: string[];
    try {
      projects = await readdir(this.options.storageRoot);
    } catch {
      return 0;
    }
    for (const project of projects) {
      const projectDir = join(this.options.storageRoot, project);
      let sessions: string[];
      try {
        sessions = await readdir(projectDir);
      } catch {
        continue;
      }
      for (const session of sessions) {
        const recordsDir = join(projectDir, session, "records");
        try {
          if (!(await stat(recordsDir)).isDirectory()) continue;
        } catch {
          continue;
        }
        total += await this.prune({ rootSessionID: session, projectID: project });
      }
    }
    return total;
  }

  /**
   * Return one-line summaries for all completed sibling sub-agents (same root
   * session, different session ID, completed before the given sessionID).
   * Each summary is truncated to maxChars characters.
   */
  async previousSummaries(
    sessionID: string,
    opts?: { limit?: number; maxChars?: number },
  ): Promise<Array<{ agent: string; summary: string; resultPath: string }>> {
    const limit = opts?.limit ?? 5;
    const maxChars = opts?.maxChars ?? 200;

    const info = await this.getSession(sessionID);
    if (!info?.parentID) return [];
    const scope = await this.resolveRootProject(sessionID);
    if (!scope) return [];

    const records = await this.entries(scope);
    const summaries: Array<{ agent: string; summary: string; resultPath: string; completed: string }> = [];

    for (const meta of records) {
      // Skip the requesting session itself
      if (meta.sessionID === sessionID) continue;
      // Only completed sub-agents (exclude failed)
      if (meta.status !== "completed") continue;
      // Only siblings (different session ID, same root)
      if (meta.rootSessionID !== scope.rootSessionID) continue;
      // Only those completed before this session started
      if (meta.completed > new Date().toISOString()) continue;

      const text = meta.sections.summary ?? meta.result;
      const oneLine = text.replace(/\s+/g, " ").slice(0, maxChars).trim();
      if (oneLine) {
        summaries.push({
          agent: meta.agent,
          summary: oneLine,
          resultPath: meta.resultPath,
          completed: meta.completed,
        });
      }
    }

    // Sort by completion time descending, take most recent
    summaries.sort((a, b) => b.completed.localeCompare(a.completed));
    return summaries.slice(0, limit).map(({ agent, summary, resultPath }) => ({ agent, summary, resultPath }));
  }
}

/**
 * Build a compact context block summarizing previous sub-agent results for
 * injection into a new sub-agent's system prompt.
 */
export function buildContextSummary(
  summaries: Array<{ agent: string; summary: string; resultPath: string }>,
  maxCharacters: number = 2_000,
): string {
  if (summaries.length === 0) return "";

  const header = "Previous sub-agent results (for context — verify against workspace):";
  const lines = summaries.map((s) => `- (${s.agent}) ${s.summary}\n  full result: ${s.resultPath}`);
  const body = [header, ...lines].join("\n");

  return truncate(body, maxCharacters);
}

const logToClient = (client: { app: { log(opts: { body: { service: string; level: string; message: string } }): unknown } }) => {
  const log = async (level: "info" | "warn" | "error", message: string) => {
    try {
      await client.app.log({ body: { service: PLUGIN_ID, level, message } });
    } catch {
      // best-effort logging never breaks the plugin
    }
  };
  return log;
};

export const OrchestrationContextPlugin: Plugin = async (
  { client, project },
  rawOptions,
) => {
  const parsed = parseContextOptions(rawOptions);
  const log = logToClient(client as Parameters<typeof logToClient>[0]);
  const { context } = parsed;

  for (const warning of parsed.warnings) await log("warn", `config: ${warning}`);

  const sessions = new Map<string, SessionInfo>();
  // Full system context (system prompt array after all plugin injections)
  // captured per child session so it can be persisted with the record.
  const systemBySession = new Map<string, string>();
  const store = new HandoffStore({
    storageRoot: context.storageRoot,
    projectID: project.id,
    scopeDepth: context.scopeDepth,
    retentionMaxRecords: context.retentionMaxRecords,
    retentionMaxAgeDays: context.retentionMaxAgeDays,
    log,
    resolver: {
      async getSession(sessionID: string) {
        const known = sessions.get(sessionID);
        if (known && (known.parentID !== undefined || known.projectID !== undefined)) return known;
        try {
          const s = (await client.session.get({
            path: { id: sessionID },
            responseStyle: "data",
            throwOnError: true,
          })) as unknown as { parentID?: string; projectID?: string };
          const info: SessionInfo = { parentID: s.parentID, projectID: s.projectID };
          sessions.set(sessionID, info);
          return info;
        } catch {
          return known;
        }
      },
      async getMessages(sessionID: string) {
        try {
          return (await client.session.messages({
            path: { id: sessionID },
            query: { limit: 1_000 },
            responseStyle: "data",
            throwOnError: true,
          })) as unknown as MessageLike[];
        } catch {
          return [];
        }
      },
    },
  });

  // Fire-and-forget startup sweep so pre-existing records are bounded even
  // when no new persist triggers a prune.
  void store.sweepAll().catch(() => undefined);

  const hooks: Hooks & { systemBySession: Map<string, string> } = {
    event: async ({ event }) => {
      if (event.type === "session.created") {
        const s = event.properties.info as unknown as { id: string; parentID?: string; projectID?: string };
        store.remember({ id: s.id, parentID: s.parentID, projectID: s.projectID });
        sessions.set(s.id, { parentID: s.parentID, projectID: s.projectID });
        return;
      }

      const isIdle =
        event.type === "session.idle" ||
        (event.type === "session.status" && (event.properties as { status?: { type?: string } }).status?.type === "idle");
      if (!isIdle) return;

      const sessionID = (event.properties as { sessionID?: string }).sessionID;
      if (!sessionID) return;
      await store.persist(sessionID, { systemContext: systemBySession.get(sessionID) });
    },

    "experimental.session.compacting": async ({ sessionID }, output) => {
      if (!sessionID) return;
      const info = await store.getSession(sessionID);
      if (!info?.parentID) return;
      const scope = await store.resolveRootProject(sessionID);
      if (!scope) return;
      output.context.push(
        `Previous sub-agent summaries are available in the system prompt. ` +
        `Read them for context, but verify all claims against the workspace.`
      );
    },

    "experimental.chat.system.transform": async ({ sessionID }, output) => {
      if (!sessionID) return;
      const info = await store.getSession(sessionID);
      if (!info?.parentID) return;

      const summaries = await store.previousSummaries(sessionID, {
        limit: 5,
        maxChars: 200,
      });
      const text = buildContextSummary(summaries, context.maxContextCharacters);
      if (text) {
        output.system.push(text);
      }

      // Capture the FULL system context as the sub-agent received it — the
      // system prompt array after all injections (includes our injected
      // "Previous sub-agent results" block). NOTE: tool definitions and the
      // final provider-assembled request payload are NOT visible from this
      // hook and are therefore not captured.
      const joined = output.system.join("\n\n");
      systemBySession.set(sessionID, joined.length > 12_000 ? truncate(joined, 12_000) : joined);
    },

    // Exposed for tests; OpenCode only reads known hook keys.
    systemBySession,
  };
  return hooks;
};

export default {
  id: PLUGIN_ID,
  server: OrchestrationContextPlugin,
};
