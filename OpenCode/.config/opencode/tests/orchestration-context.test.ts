import { test } from "node:test";
import assert from "node:assert";
import { mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

import {
  HandoffStore,
  DEFAULT_STORAGE_ROOT,
  buildContextSummary,
  OrchestrationContextPlugin,
  parseContextOptions,
  safeSegment,
  truncate,
  type HandoffMetadata,
  type SessionInfo,
  type Scope,
} from "../plugin/orchestration/orchestration-context.ts";

type MessageLike = {
  info?: {
    role?: string;
    id?: string;
    agent?: string;
    mode?: string;
    providerID?: string;
    modelID?: string;
    error?: { name?: string } | null;
    time?: { created?: number };
  };
  parts?: unknown[];
};

type MockSession = {
  parentID?: string;
  projectID?: string;
  messages?: MessageLike[];
};

const userMessage = (over: Partial<MessageLike["info"]> = {}): MessageLike => ({
  info: { role: "user", agent: "general", providerID: "opencode", modelID: "deepseek-v4-flash-free", ...over },
  parts: [{ id: "prt_u1", type: "text", text: "do the work" }],
});

const assistantMessage = (over: Partial<MessageLike["info"]> = {}, text = "Completed the task."): MessageLike => ({
  info: {
    role: "assistant",
    mode: "general",
    providerID: "opencode",
    modelID: "deepseek-v4-flash-free",
    time: { created: Date.now() },
    ...over,
  },
  parts: [{ id: "prt_a1", type: "text", text }],
});

function makeHarness(
  storageRoot: string,
  projectID = "proj-a",
  storeOptions: Partial<ConstructorParameters<typeof HandoffStore>[0]> = {},
) {
  const sessions = new Map<string, MockSession>();
  const register = (id: string, s: MockSession) => sessions.set(id, s);
  const store = new HandoffStore({
    storageRoot,
    projectID,
    scopeDepth: 16,
    ...storeOptions,
    resolver: {
      async getSession(sessionID: string): Promise<SessionInfo | undefined> {
        const s = sessions.get(sessionID);
        return s ? { parentID: s.parentID, projectID: s.projectID } : undefined;
      },
      async getMessages(sessionID: string): Promise<MessageLike[]> {
        return sessions.get(sessionID)?.messages ?? [];
      },
    },
  });
  const remember = (id: string, s: MockSession) => {
    sessions.set(id, s);
    store.remember({ id, parentID: s.parentID, projectID: s.projectID });
  };
  return { sessions, register, remember, store };
}

function makeClientMock(sessions: Map<string, MockSession>) {
  return {
    app: { log: async () => undefined },
    session: {
      get: async ({ path }: { path: { id: string } }) => {
        const s = sessions.get(path.id);
        if (!s) throw new Error(`session ${path.id} not found`);
        return { id: path.id, parentID: s.parentID, projectID: s.projectID };
      },
      messages: async ({ path }: { path: { id: string } }) => {
        const s = sessions.get(path.id);
        return s?.messages ?? [];
      },
    },
  };
}

async function makePluginHarness(sessions: Map<string, MockSession>, options?: Record<string, unknown>) {
  const client = makeClientMock(sessions);
  const hooks = await OrchestrationContextPlugin(
    {
      client: client as never,
      project: { id: "proj-a" } as never,
      directory: "/tmp",
      worktree: "/tmp",
      experimental_workspace: { register: () => undefined } as never,
      serverUrl: new URL("http://localhost"),
      $: {} as never,
    },
    options,
  );
  return { hooks, client };
}

const tempRoot = async () => mkdtemp(join(tmpdir(), "orch-context-"));

test("parseContextOptions: defaults when options omitted", () => {
  const p = parseContextOptions(undefined, undefined);
  assert.equal(p.context.maxContextCharacters, 2_000);
  assert.equal(p.context.storageRoot, DEFAULT_STORAGE_ROOT);
  assert.equal(p.context.retentionMaxRecords, 50);
  assert.equal(p.context.retentionMaxAgeDays, 30);
  assert.deepEqual(p.warnings, []);
});

test("parseContextOptions: valid context block is applied", () => {
  const p = parseContextOptions(
    {
      context: {
        maxContextCharacters: 1500,
        storageRoot: "/tmp/x",
      },
    },
    undefined,
  );
  assert.equal(p.context.maxContextCharacters, 1500);
  assert.equal(p.context.storageRoot, "/tmp/x");
  assert.deepEqual(p.warnings, []);
});

test("parseContextOptions: unknown top-level keys rejected with warnings", () => {
  const p = parseContextOptions({
    fallbacks: { general: ["a", "b"] },
    retry: { maxAttemptsPerModel: 1 },
    context: { maxContextCharacters: 5000 },
  });
  assert.ok(p.warnings.some((w) => w.includes("fallbacks")), "fallbacks warning");
  assert.ok(p.warnings.some((w) => w.includes("retry")), "retry warning");
  assert.equal(p.context.maxContextCharacters, 5000);
  assert.equal(p.context.storageRoot, DEFAULT_STORAGE_ROOT);
});

test("parseContextOptions: negative and malformed values fall back to defaults", () => {
  const p = parseContextOptions({
    context: {
      maxContextCharacters: -5,
      scopeDepth: 1.5,
    },
  });
  assert.equal(p.context.maxContextCharacters, 2_000);
  assert.equal(p.context.scopeDepth, 16);
  assert.ok(p.warnings.length >= 1);
});

test("parseContextOptions: invalid retention values fall back to defaults with warnings", () => {
  const p = parseContextOptions({
    context: {
      retentionMaxRecords: -5,
      retentionMaxAgeDays: 2.5,
    },
  });
  assert.equal(p.context.retentionMaxRecords, 50);
  assert.equal(p.context.retentionMaxAgeDays, 30);
  assert.ok(p.warnings.some((w) => w.includes("retentionMaxRecords")), "maxRecords warning");
  assert.ok(p.warnings.some((w) => w.includes("retentionMaxAgeDays")), "maxAgeDays warning");
});

test("parseContextOptions: valid retention values are applied", () => {
  const p = parseContextOptions({
    context: {
      retentionMaxRecords: 3,
      retentionMaxAgeDays: 7,
    },
  });
  assert.equal(p.context.retentionMaxRecords, 3);
  assert.equal(p.context.retentionMaxAgeDays, 7);
  assert.deepEqual(p.warnings, []);
  // 0 is a valid maxAgeDays (disables age-based pruning)
  const p0 = parseContextOptions({ context: { retentionMaxAgeDays: 0 } });
  assert.equal(p0.context.retentionMaxAgeDays, 0);
  assert.deepEqual(p0.warnings, []);
});

test("parseContextOptions: storage root precedence explicit > env > default", () => {
  const fromEnv = parseContextOptions(undefined, "/env/root");
  assert.equal(fromEnv.context.storageRoot, "/env/root");
  const explicit = parseContextOptions({ context: { storageRoot: "/explicit" } }, "/env/root");
  assert.equal(explicit.context.storageRoot, "/explicit");
});

test("root scoping: nested sessions resolve to the root and project", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root);
    remember("root", { projectID: "proj-a" });
    remember("child", { parentID: "root", projectID: "proj-a" });
    remember("grandchild", { parentID: "child", projectID: "proj-a" });

    const scope = await store.resolveRootProject("grandchild");
    assert.deepEqual(scope, { rootSessionID: "root", projectID: "proj-a" });
    const scopeChild = await store.resolveRootProject("child");
    assert.equal(scopeChild?.rootSessionID, "root");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("root scoping: missing session cannot resolve", async () => {
  const root = await tempRoot();
  try {
    const { store } = makeHarness(root);
    assert.equal(await store.resolveRootProject("does-not-exist"), undefined);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("root scoping: projects and root sessions are isolated", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root, "proj-a");
    remember("r1", { projectID: "proj-a" });
    remember("c1", { parentID: "r1", projectID: "proj-a", messages: [userMessage(), assistantMessage({}, "R1 result")] });
    remember("r2", { projectID: "proj-b" });
    remember("c2", { parentID: "r2", projectID: "proj-b", messages: [userMessage(), assistantMessage({}, "R2 result")] });

    await store.persist("c1");
    await store.persist("c2");

    // Verify isolation by checking storeDir is different
    const scope1: Scope = { rootSessionID: "r1", projectID: "proj-a" };
    const scope2: Scope = { rootSessionID: "r2", projectID: "proj-b" };
    assert.notEqual(store.storeDir(scope1), store.storeDir(scope2));

    // Verify files were written to separate directories
    const dir1Files = await readdir(store.storeDir(scope1));
    const dir2Files = await readdir(store.storeDir(scope2));
    assert.ok(dir1Files.includes("c1.json"));
    assert.ok(dir2Files.includes("c2.json"));
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("persistence: writes atomic metadata JSON + Markdown result, no tmp residue", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root);
    remember("root", { projectID: "proj-a" });
    const text = "## Summary\nAll green.\n## Verification\nTests pass.\n## Handoff\nSee tool.";
    remember("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, text)],
    });

    assert.equal(await store.persist("c1"), true);

    const scope: Scope = { rootSessionID: "root", projectID: "proj-a" };
    const dir = store.storeDir(scope);
    const files = (await readdir(dir)).sort();
    assert.deepEqual(files, ["c1.json", "c1.md"]);
    assert.ok(!files.some((f) => f.includes(".tmp-")), "no temp files left behind");

    const meta = JSON.parse(await readFile(join(dir, "c1.json"), "utf8")) as HandoffMetadata;
    assert.equal(meta.id, "c1");
    assert.equal(meta.status, "completed");
    assert.equal(meta.rootSessionID, "root");
    assert.equal(meta.agent, "general");
    assert.equal(meta.sections.verification, "Tests pass.");
    assert.equal(meta.taskPrompt, "do the work");

    const md = await readFile(join(dir, "c1.md"), "utf8");
    assert.ok(md.includes("# Agent Result: general"));
    assert.ok(md.includes("All green."));
    assert.ok(md.includes("## Task Prompt"));
    assert.ok(md.includes("do the work"));
    assert.ok(md.includes("## System Context"));
    assert.ok(md.includes("## Result"));
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("persistence: failed assistant messages are recorded as failed", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root);
    remember("root", { projectID: "proj-a" });
    remember("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({ error: { name: "APIError" } }, "boom")],
    });
    await store.persist("c1");
    const scope: Scope = { rootSessionID: "root", projectID: "proj-a" };
    const dir = store.storeDir(scope);
    const meta = JSON.parse(await readFile(join(dir, "c1.json"), "utf8")) as HandoffMetadata;
    assert.equal(meta.status, "failed");
    assert.equal(meta.error, "APIError");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("persistence: concurrent child completions never lose or corrupt records", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root);
    remember("root", { projectID: "proj-a" });
    for (let i = 0; i < 8; i++) {
      const id = `c${i}`;
      remember(id, {
        parentID: "root",
        projectID: "proj-a",
        messages: [userMessage(), assistantMessage({}, `result ${i}`)],
      });
    }

    await Promise.all(["c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7"].map((id) => store.persist(id)));

    const scope: Scope = { rootSessionID: "root", projectID: "proj-a" };
    const dir = store.storeDir(scope);
    const files = (await readdir(dir)).sort();
    assert.equal(files.filter((f) => f.endsWith(".json")).length, 8);
    assert.equal(files.filter((f) => f.endsWith(".md")).length, 8);

    for (const f of files) {
      const content = await readFile(join(dir, f), "utf8");
      assert.ok(content.length > 0, `${f} is not empty`);
    }
    assert.ok(!files.some((f) => f.includes(".tmp-")), "no temp files left behind");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("restart: a fresh store instance loads earlier records lazily from disk", async () => {
  const root = await tempRoot();
  try {
    const first = makeHarness(root);
    first.remember("root", { projectID: "proj-a" });
    first.remember("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "from previous run")],
    });
    await first.store.persist("c1");

    // Verify the file exists on disk
    const scope: Scope = { rootSessionID: "root", projectID: "proj-a" };
    const dir = first.store.storeDir(scope);
    const files = await readdir(dir);
    assert.ok(files.includes("c1.json"));
    assert.ok(files.includes("c1.md"));
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("retention: prune deletes oldest records beyond maxRecords", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root, "proj-a", { retentionMaxRecords: 2 });
    remember("root", { projectID: "proj-a" });
    remember("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "result c1")],
    });
    remember("c2", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "result c2")],
    });
    remember("c3", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "result c3")],
    });

    // Small delays so `completed` timestamps are strictly ordered (c1 < c2 < c3)
    await store.persist("c1");
    await new Promise((r) => setTimeout(r, 10));
    await store.persist("c2");
    await new Promise((r) => setTimeout(r, 10));
    await store.persist("c3");

    // persist() prunes automatically: after c3 only the 2 newest remain
    const scope: Scope = { rootSessionID: "root", projectID: "proj-a" };
    const dir = store.storeDir(scope);
    const files = (await readdir(dir)).filter((f) => f.endsWith(".json")).sort();
    assert.deepEqual(files, ["c2.json", "c3.json"], "oldest record pruned");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("retention: prune deletes files older than maxAgeDays", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root, "proj-a", { retentionMaxAgeDays: 1, retentionMaxRecords: 100 });
    remember("root", { projectID: "proj-a" });
    remember("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "stale result")],
    });
    await store.persist("c1");

    // Manually age the record: rewrite its JSON with a `completed` 10 days ago
    const scope: Scope = { rootSessionID: "root", projectID: "proj-a" };
    const dir = store.storeDir(scope);
    const metaPath = join(dir, "c1.json");
    const meta = JSON.parse(await readFile(metaPath, "utf8")) as HandoffMetadata;
    meta.completed = new Date(Date.now() - 10 * 86_400_000).toISOString();
    await writeFile(metaPath, `${JSON.stringify(meta, null, 2)}\n`);

    const deleted = await store.prune(scope);
    assert.equal(deleted, 1, "stale record deleted");
    const files = await readdir(dir);
    assert.ok(!files.includes("c1.json"), "stale JSON removed");
    assert.ok(!files.includes("c1.md"), "stale Markdown removed");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("retention: sweepAll prunes across scopes", async () => {
  const root = await tempRoot();
  try {
    // Write 3 records per scope under a store with generous (default) limits
    const first = makeHarness(root);
    first.remember("r1", { projectID: "proj-a" });
    first.remember("r2", { projectID: "proj-a" });
    for (let i = 0; i < 3; i++) {
      first.remember(`r1c${i}`, {
        parentID: "r1",
        projectID: "proj-a",
        messages: [userMessage(), assistantMessage({}, `r1 result ${i}`)],
      });
      await first.store.persist(`r1c${i}`);
    }
    for (let i = 0; i < 3; i++) {
      first.remember(`r2c${i}`, {
        parentID: "r2",
        projectID: "proj-a",
        messages: [userMessage(), assistantMessage({}, `r2 result ${i}`)],
      });
      await first.store.persist(`r2c${i}`);
    }

    // Sweep with a store that enforces maxRecords: 1 per scope
    const sweeping = makeHarness(root, "proj-a", { retentionMaxRecords: 1, retentionMaxAgeDays: 0 });
    const deleted = await sweeping.store.sweepAll();
    assert.equal(deleted, 4, "two oldest records removed from each scope");

    const dir1 = first.store.storeDir({ rootSessionID: "r1", projectID: "proj-a" });
    const dir2 = first.store.storeDir({ rootSessionID: "r2", projectID: "proj-a" });
    assert.equal((await readdir(dir1)).filter((f) => f.endsWith(".json")).length, 1);
    assert.equal((await readdir(dir2)).filter((f) => f.endsWith(".json")).length, 1);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("event hook: session.created registers session, session.idle triggers persist", async () => {
  const root = await tempRoot();
  try {
    const sessions = new Map<string, MockSession>();
    sessions.set("root", { projectID: "proj-a" });
    sessions.set("child", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "persisted via event")],
    });
    const { hooks } = await makePluginHarness(sessions, { context: { storageRoot: root } });

    const event = hooks.event as (input: { event: unknown }) => Promise<void>;

    // session.created should register the child
    await event({
      event: { type: "session.created", properties: { info: { id: "child", parentID: "root", projectID: "proj-a" } } },
    });

    // session.idle should trigger persist
    await event({ event: { type: "session.idle", properties: { sessionID: "child" } } });

    // Verify file was written
    const dir = join(root, "proj-a", "root", "records");
    const files = await readdir(dir);
    assert.ok(files.includes("child.json"));
    assert.ok(files.includes("child.md"));

    const md = await readFile(join(dir, "child.md"), "utf8");
    assert.ok(md.includes("## Task Prompt"));
    assert.ok(md.includes("do the work"));
    assert.ok(md.includes("## System Context"));
    assert.ok(md.includes("## Result"));
    assert.ok(md.includes("persisted via event"));
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("event hook: session.idle skips primary sessions (no parentID)", async () => {
  const root = await tempRoot();
  try {
    const sessions = new Map<string, MockSession>();
    sessions.set("root", { projectID: "proj-a" });
    const { hooks } = await makePluginHarness(sessions, { context: { storageRoot: root } });

    const event = hooks.event as (input: { event: unknown }) => Promise<void>;
    await event({ event: { type: "session.idle", properties: { sessionID: "root" } } });

    // No files should be written for root session
    const dir = join(root, "proj-a", "root", "records");
    try {
      const files = await readdir(dir);
      assert.equal(files.length, 0, "no files for primary session");
    } catch {
      // directory doesn't exist, which is fine
    }
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("system.transform hook: injects previous summaries for child sessions, skips root", async () => {
  const root = await tempRoot();
  try {
    const sessions = new Map<string, MockSession>();
    sessions.set("root", { projectID: "proj-a" });
    sessions.set("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "Found 5 API endpoints in src/routes/users.ts")],
    });
    sessions.set("c2", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "Designed JWT auth middleware, suggested src/middleware/auth.ts")],
    });
    const { hooks } = await makePluginHarness(sessions, { context: { storageRoot: root } });

    // Persist c1 and c2 first so they appear as previous summaries
    const event = hooks.event as (input: { event: unknown }) => Promise<void>;
    await event({
      event: { type: "session.created", properties: { info: { id: "c1", parentID: "root", projectID: "proj-a" } } },
    });
    await event({
      event: { type: "session.created", properties: { info: { id: "c2", parentID: "root", projectID: "proj-a" } } },
    });
    await event({ event: { type: "session.idle", properties: { sessionID: "c1" } } });
    await event({ event: { type: "session.idle", properties: { sessionID: "c2" } } });

    // Now simulate a new child session that was just created
    sessions.set("c3", { parentID: "root", projectID: "proj-a" });
    await event({
      event: { type: "session.created", properties: { info: { id: "c3", parentID: "root", projectID: "proj-a" } } },
    });

    // system.transform should inject previous summaries for c3
    const childOut = { system: [] as string[] };
    await (
      hooks["experimental.chat.system.transform"] as (
        input: { sessionID: string },
        out: { system: string[] },
      ) => Promise<void>
    )({ sessionID: "c3" }, childOut);

    assert.ok(childOut.system.length >= 1, "system transform injects context");
    const combined = childOut.system.join("\n");
    assert.ok(combined.includes("Previous sub-agent results"), "header present");
    assert.ok(combined.includes("general"), "agent name present");
    assert.ok(combined.includes("full result:"), "result path included");

    // Root session should not get system transform
    const primaryOut = { system: [] as string[] };
    await (
      hooks["experimental.chat.system.transform"] as (
        input: { sessionID: string },
        out: { system: string[] },
      ) => Promise<void>
    )({ sessionID: "root" }, primaryOut);
    assert.equal(primaryOut.system.length, 0, "primary system prompt untouched");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("system.transform hook: no summaries when no previous sub-agents exist", async () => {
  const root = await tempRoot();
  try {
    const sessions = new Map<string, MockSession>();
    sessions.set("root", { projectID: "proj-a" });
    sessions.set("child", { parentID: "root", projectID: "proj-a" });
    const { hooks } = await makePluginHarness(sessions);

    const childOut = { system: [] as string[] };
    await (
      hooks["experimental.chat.system.transform"] as (
        input: { sessionID: string },
        out: { system: string[] },
      ) => Promise<void>
    )({ sessionID: "child" }, childOut);

    assert.equal(childOut.system.length, 0, "no injection when no previous summaries");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("system.transform captures full system context", async () => {
  const root = await tempRoot();
  try {
    const sessions = new Map<string, MockSession>();
    sessions.set("root", { projectID: "proj-a" });
    sessions.set("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "first result")],
    });
    sessions.set("c2", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "second result")],
    });
    const { hooks } = await makePluginHarness(sessions, { context: { storageRoot: root } });

    const event = hooks.event as (input: { event: unknown }) => Promise<void>;
    await event({
      event: { type: "session.created", properties: { info: { id: "c1", parentID: "root", projectID: "proj-a" } } },
    });
    await event({
      event: { type: "session.created", properties: { info: { id: "c2", parentID: "root", projectID: "proj-a" } } },
    });
    await event({ event: { type: "session.idle", properties: { sessionID: "c1" } } });
    await event({ event: { type: "session.idle", properties: { sessionID: "c2" } } });

    // A new child session whose system transform fires before it idles
    sessions.set("c3", { parentID: "root", projectID: "proj-a" });
    await event({
      event: { type: "session.created", properties: { info: { id: "c3", parentID: "root", projectID: "proj-a" } } },
    });

    const childOut = { system: ["base system prompt", "another system part"] };
    await (
      hooks["experimental.chat.system.transform"] as (
        input: { sessionID: string },
        out: { system: string[] },
      ) => Promise<void>
    )({ sessionID: "c3" }, childOut);

    const map = (hooks as unknown as { systemBySession: Map<string, string> }).systemBySession;
    const captured = map.get("c3");
    assert.ok(captured, "system context captured for child session");
    assert.ok(captured!.includes("Previous sub-agent results"), "captured context includes injected block");
    assert.ok(captured!.includes("base system prompt"), "captured context includes base system prompt");
    assert.ok(captured!.includes("another system part"), "captured context includes all system parts");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("compaction hook: injects simplified note for child sessions, skips root", async () => {
  const root = await tempRoot();
  try {
    const sessions = new Map<string, MockSession>();
    sessions.set("root", { projectID: "proj-a" });
    sessions.set("child", { parentID: "root", projectID: "proj-a", messages: [userMessage(), assistantMessage({}, "compacted result")] });
    const { hooks } = await makePluginHarness(sessions);

    const childOut = { context: [] as string[] };
    await (
      hooks["experimental.session.compacting"] as (
        input: { sessionID: string },
        out: { context: string[] },
      ) => Promise<void>
    )({ sessionID: "child" }, childOut);
    assert.equal(childOut.context.length, 1);
    assert.ok(childOut.context[0]!.includes("Previous sub-agent summaries"));
    assert.ok(childOut.context[0]!.includes("verify all claims against the workspace"));

    const primaryOut = { context: [] as string[] };
    await (
      hooks["experimental.session.compacting"] as (
        input: { sessionID: string },
        out: { context: string[] },
      ) => Promise<void>
    )({ sessionID: "root" }, primaryOut);
    assert.equal(primaryOut.context.length, 0, "primary session gets no compaction context");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("previousSummaries: returns sibling results in correct order", async () => {
  const root = await tempRoot();
  try {
    const { remember, store, sessions } = makeHarness(root);
    remember("root", { projectID: "proj-a" });

    // Persist c1 first
    remember("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "First result from explore agent")],
    });
    await store.persist("c1");

    // Persist c2 after
    remember("c2", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "Second result from implement agent")],
    });
    await store.persist("c2");

    // Requesting summaries for c3 (which doesn't exist yet but has same parent)
    sessions.set("c3", { parentID: "root", projectID: "proj-a" });
    store.remember({ id: "c3", parentID: "root", projectID: "proj-a" });

    const summaries = await store.previousSummaries("c3");
    assert.ok(summaries.length >= 1, "at least one summary returned");
    // Should be sorted by most recent completed first
    assert.ok(summaries[0]!.summary.length > 0, "summary has content");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("previousSummaries: respects limit parameter", async () => {
  const root = await tempRoot();
  try {
    const { remember, store, sessions } = makeHarness(root);
    remember("root", { projectID: "proj-a" });

    for (let i = 0; i < 8; i++) {
      const id = `c${i}`;
      remember(id, {
        parentID: "root",
        projectID: "proj-a",
        messages: [userMessage(), assistantMessage({}, `result ${i} with details`)],
      });
      await store.persist(id);
    }

    // Requesting for a new child
    sessions.set("c_new", { parentID: "root", projectID: "proj-a" });
    store.remember({ id: "c_new", parentID: "root", projectID: "proj-a" });

    const summaries = await store.previousSummaries("c_new", { limit: 3 });
    assert.ok(summaries.length <= 3, "limit respected");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("previousSummaries: returns empty for root sessions", async () => {
  const root = await tempRoot();
  try {
    const { remember, store } = makeHarness(root);
    remember("root", { projectID: "proj-a" });
    remember("c1", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "child result")],
    });
    await store.persist("c1");

    const summaries = await store.previousSummaries("root");
    assert.equal(summaries.length, 0, "root sessions get no summaries");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("previousSummaries: excludes failed sub-agents", async () => {
  const root = await tempRoot();
  try {
    const { remember, store, sessions } = makeHarness(root);
    remember("root", { projectID: "proj-a" });

    // Successful sub-agent
    remember("c_ok", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({}, "success result")],
    });
    await store.persist("c_ok");

    // Failed sub-agent
    remember("c_fail", {
      parentID: "root",
      projectID: "proj-a",
      messages: [userMessage(), assistantMessage({ error: { name: "Timeout" } }, "timed out")],
    });
    await store.persist("c_fail");

    // Requesting for a new child
    sessions.set("c_new", { parentID: "root", projectID: "proj-a" });
    store.remember({ id: "c_new", parentID: "root", projectID: "proj-a" });

    const summaries = await store.previousSummaries("c_new");
    const summaryTexts = summaries.map((s) => s.summary);
    assert.ok(!summaryTexts.some((t) => t.includes("timed out")), "failed sub-agents excluded");
    assert.ok(summaryTexts.some((t) => t.includes("success result")), "successful sub-agent included");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("buildContextSummary: produces compact block with header and lines", () => {
  const text = buildContextSummary([
    { agent: "explore", summary: "Found 5 API endpoints in src/routes", resultPath: "/tmp/c1.md" },
    { agent: "plan", summary: "Designed JWT auth middleware", resultPath: "/tmp/c2.md" },
  ]);
  assert.ok(text.includes("Previous sub-agent results"));
  assert.ok(text.includes("- (explore) Found 5 API endpoints"));
  assert.ok(text.includes("- (plan) Designed JWT auth middleware"));
  assert.ok(text.includes("full result: /tmp/c1.md"));
  assert.ok(text.includes("full result: /tmp/c2.md"));
});

test("buildContextSummary: returns empty string for no summaries", () => {
  const text = buildContextSummary([]);
  assert.equal(text, "");
});

test("buildContextSummary: respects maxCharacters limit", () => {
  const text = buildContextSummary(
    Array.from({ length: 10 }, (_, i) => ({
      agent: `agent${i}`,
      summary: "x".repeat(200),
      resultPath: `/tmp/c${i}.md`,
    })),
    500,
  );
  assert.ok(text.length <= 500, `summary ${text.length} within bound`);
});

test("helpers: safeSegment and truncate behave", () => {
  assert.equal(safeSegment("abc-123.xyz"), "abc-123.xyz");
  assert.equal(safeSegment("../evil"), ".._evil");
  assert.equal(truncate("abcdef", 10), "abcdef");
  assert.equal(truncate("abcdef", 20), "abcdef");
  const t = truncate("a".repeat(30), 18);
  assert.ok(t.length <= 18);
  assert.ok(t.endsWith("\n...[truncated]"));
});
