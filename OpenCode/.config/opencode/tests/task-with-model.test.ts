import { test } from "node:test";
import assert from "node:assert";

import {
  MAX_STICKY_ENTRIES,
  StickyModelStore,
  childSessionTitle,
  flattenModelIDs,
  handleSubagentModelCommand,
  isResetSentinel,
  normalizeCommandName,
  parseModelRef,
  resolveTaskModel,
  type ModelRef,
} from "../plugin/orchestration/task-model.ts";

const COST: ModelRef = { providerID: "abacate", modelID: "cost" };
const PERFORMANCE: ModelRef = { providerID: "abacate", modelID: "performance" };
const PARENT: ModelRef = { providerID: "opencode", modelID: "parent-model" };

const freshStore = () => new StickyModelStore();

test("parseModelRef accepts provider/model-id", () => {
  assert.deepStrictEqual(parseModelRef("abacate/cost"), COST);
});

test("parseModelRef splits on the first slash so model IDs may contain slashes", () => {
  assert.deepStrictEqual(parseModelRef("nvidia/meta/llama-3.1-8b-instruct"), {
    providerID: "nvidia",
    modelID: "meta/llama-3.1-8b-instruct",
  });
});

test("parseModelRef trims surrounding whitespace", () => {
  assert.deepStrictEqual(parseModelRef("  abacate/cost  "), COST);
});

test("parseModelRef rejects values without a usable provider and model", () => {
  for (const bad of ["", "   ", "noprovider", "/model", "provider/", "/"]) {
    assert.throws(() => parseModelRef(bad), /Invalid model/, JSON.stringify(bad));
  }
});

test("reset sentinels are recognized case-insensitively with whitespace", () => {
  for (const sentinel of ["reset", "pinned", "default", " Reset ", "PINNED"]) {
    assert.strictEqual(isResetSentinel(sentinel), true, sentinel);
  }
  assert.strictEqual(isResetSentinel("abacate/cost"), false);
});

test("explicit model wins and becomes the session sticky default", () => {
  const sticky = freshStore();
  const first = resolveTaskModel({
    requested: "abacate/performance",
    sticky,
    sessionID: "ses-root",
    agentModel: COST,
    parentModel: PARENT,
  });
  assert.strictEqual(first.kind, "explicit");
  assert.deepStrictEqual(first.model, PERFORMANCE);
  assert.deepStrictEqual(sticky.get("ses-root"), PERFORMANCE);

  // A later call without a model reuses the sticky default, not the pin.
  const second = resolveTaskModel({
    requested: undefined,
    sticky,
    sessionID: "ses-root",
    agentModel: COST,
    parentModel: PARENT,
  });
  assert.strictEqual(second.kind, "sticky");
  assert.deepStrictEqual(second.model, PERFORMANCE);
});

test("explicit model replaces a previous sticky default", () => {
  const sticky = freshStore();
  sticky.set("ses-root", PERFORMANCE);
  const resolution = resolveTaskModel({
    requested: "abacate/cost",
    sticky,
    sessionID: "ses-root",
    agentModel: PERFORMANCE,
    parentModel: PARENT,
  });
  assert.strictEqual(resolution.kind, "explicit");
  assert.deepStrictEqual(resolution.model, COST);
  assert.deepStrictEqual(sticky.get("ses-root"), COST);
});

test("sticky defaults are scoped per session", () => {
  const sticky = freshStore();
  sticky.set("ses-a", PERFORMANCE);
  const other = resolveTaskModel({
    requested: undefined,
    sticky,
    sessionID: "ses-b",
    agentModel: COST,
    parentModel: PARENT,
  });
  assert.strictEqual(other.kind, "default");
  assert.deepStrictEqual(other.model, COST);
});

test("reset sentinel clears the sticky default and falls back to the pin", () => {
  const sticky = freshStore();
  sticky.set("ses-root", PERFORMANCE);
  const resolution = resolveTaskModel({
    requested: "reset",
    sticky,
    sessionID: "ses-root",
    agentModel: COST,
    parentModel: PARENT,
  });
  assert.strictEqual(resolution.kind, "reset");
  assert.deepStrictEqual(resolution.model, COST);
  assert.strictEqual(sticky.get("ses-root"), undefined);

  const after = resolveTaskModel({
    requested: undefined,
    sticky,
    sessionID: "ses-root",
    agentModel: COST,
    parentModel: PARENT,
  });
  assert.strictEqual(after.kind, "default");
  assert.deepStrictEqual(after.model, COST);
});

test("fallback order without stickiness is pin, then parent model", () => {
  const withPin = resolveTaskModel({
    requested: undefined,
    sticky: freshStore(),
    sessionID: "ses-root",
    agentModel: COST,
    parentModel: PARENT,
  });
  assert.strictEqual(withPin.kind, "default");
  assert.deepStrictEqual(withPin.model, COST);

  const withoutPin = resolveTaskModel({
    requested: undefined,
    sticky: freshStore(),
    sessionID: "ses-root",
    agentModel: undefined,
    parentModel: PARENT,
  });
  assert.deepStrictEqual(withoutPin.model, PARENT);

  const withoutAnything = resolveTaskModel({
    requested: undefined,
    sticky: freshStore(),
    sessionID: "ses-root",
    agentModel: undefined,
    parentModel: undefined,
  });
  assert.strictEqual(withoutAnything.model, undefined);
});

test("StickyModelStore clear/prune report and remove entries", () => {
  const sticky = freshStore();
  assert.strictEqual(sticky.clear("missing"), false);
  sticky.set("ses-root", COST);
  assert.strictEqual(sticky.clear("ses-root"), true);
  assert.strictEqual(sticky.get("ses-root"), undefined);
  sticky.set("ses-root", COST);
  sticky.prune("ses-root");
  assert.strictEqual(sticky.get("ses-root"), undefined);
});

test("StickyModelStore evicts the oldest entry past the cap", () => {
  const sticky = new StickyModelStore(2);
  sticky.set("ses-1", COST);
  sticky.set("ses-2", COST);
  sticky.set("ses-3", PERFORMANCE);
  assert.strictEqual(sticky.size, 2);
  assert.strictEqual(sticky.get("ses-1"), undefined);
  assert.deepStrictEqual(sticky.get("ses-3"), PERFORMANCE);
  assert.strictEqual(MAX_STICKY_ENTRIES, 200);
});

test("child session title matches the built-in task tool format", () => {
  assert.strictEqual(childSessionTitle("Fix login bug", "general"), "Fix login bug (@general subagent)");
});

test("normalizeCommandName strips slash and lowercases", () => {
  assert.strictEqual(normalizeCommandName("/Subagent-Model"), "subagent-model");
  assert.strictEqual(normalizeCommandName("  subagent-model  "), "subagent-model");
  assert.strictEqual(normalizeCommandName("other"), "other");
});

test("/subagent-model with a model sets the sticky default and confirms", () => {
  const sticky = freshStore();
  const result = handleSubagentModelCommand({
    requested: "abacate/performance",
    sticky,
    sessionID: "ses-root",
  });
  assert.deepStrictEqual(sticky.get("ses-root"), PERFORMANCE);
  assert.match(result.text, /abacate\/performance/);
});

test("/subagent-model with no args reports the current default", () => {
  const sticky = freshStore();
  const empty = handleSubagentModelCommand({ requested: "  ", sticky, sessionID: "ses-root" });
  assert.match(empty.text, /pinned model/);

  sticky.set("ses-root", PERFORMANCE);
  const current = handleSubagentModelCommand({ requested: "", sticky, sessionID: "ses-root" });
  assert.match(current.text, /abacate\/performance/);
});

test("/subagent-model reset clears the sticky default", () => {
  const sticky = freshStore();
  sticky.set("ses-root", PERFORMANCE);
  const result = handleSubagentModelCommand({ requested: "reset", sticky, sessionID: "ses-root" });
  assert.strictEqual(sticky.get("ses-root"), undefined);
  assert.match(result.text, /pinned models/);
});

test("/subagent-model with an invalid model throws a helpful error", () => {
  assert.throws(
    () => handleSubagentModelCommand({ requested: "nonsense", sticky: freshStore(), sessionID: "ses-root" }),
    /Invalid model/,
  );
});

test("flattenModelIDs sorts per provider, caps output, and counts the total", () => {
  const { ids, total } = flattenModelIDs(
    [
      { id: "b", models: { zed: {}, apple: {} } },
      { id: "a", models: { one: {}, two: {}, three: {} } },
    ],
    3,
  );
  assert.deepStrictEqual(ids, ["b/apple", "b/zed", "a/one"]);
  assert.strictEqual(total, 5);
});

test("/subagent-model status lists available models and notes truncation", () => {
  const sticky = freshStore();
  const result = handleSubagentModelCommand({
    requested: "",
    sticky,
    sessionID: "ses-root",
    availableModels: { ids: ["abacate/cost", "abacate/performance"], total: 5 },
  });
  assert.match(result.text, /abacate\/cost/);
  assert.match(result.text, /…and 3 more/);
});

test("command hook mutates the parts array in place (reassignment is ignored by the server)", async () => {
  const { TaskWithModelPlugin } = await import("../plugin/orchestration/task-with-model.ts");
  const client = {
    app: { log: async () => undefined },
    config: {
      providers: async () => ({ providers: [{ id: "abacate", models: { cost: {}, performance: {} } }] }),
    },
    session: {
      get: async () => {
        throw new Error("no session");
      },
      messages: async () => [],
    },
  };
  const hooks = await TaskWithModelPlugin({
    client: client as never,
    project: { id: "proj-a" } as never,
    directory: "/tmp",
    worktree: "/tmp",
    experimental_workspace: { register: () => undefined } as never,
    serverUrl: new URL("http://localhost"),
    $: {} as never,
  });
  const hook = hooks["command.execute.before"];
  assert.ok(hook, "command hook is registered");

  // Bare invocation: the SAME array reference must carry the status text.
  const statusOutput = { parts: [{ type: "text", text: "template" }] };
  const statusRef = statusOutput.parts;
  await hook({ command: "subagent-model", sessionID: "ses-cmd", arguments: "" }, statusOutput as never);
  assert.strictEqual(statusOutput.parts, statusRef, "hook must mutate parts in place, not reassign");
  assert.strictEqual(statusOutput.parts.length, 1);
  assert.match(statusOutput.parts[0].text, /Sub-agent model default for this session: \(none/);
  assert.match(statusOutput.parts[0].text, /abacate\/performance/);

  // Unrelated commands pass through untouched.
  const passthrough = { parts: [{ type: "text", text: "template" }] };
  await hook({ command: "other", sessionID: "ses-cmd", arguments: "" }, passthrough as never);
  assert.deepStrictEqual(passthrough.parts, [{ type: "text", text: "template" }]);

  // With-args invocation sets the sticky default for later bare calls.
  const setOutput = { parts: [{ type: "text", text: "template" }] };
  await hook(
    { command: "/SUBAGENT-MODEL", sessionID: "ses-cmd", arguments: "abacate/performance" },
    setOutput as never,
  );
  assert.match(setOutput.parts[0].text, /set to abacate\/performance/);
  const afterOutput = { parts: [{ type: "text", text: "template" }] };
  await hook({ command: "subagent-model", sessionID: "ses-cmd", arguments: "  " }, afterOutput as never);
  assert.match(afterOutput.parts[0].text, /default for this session: abacate\/performance/);
});
