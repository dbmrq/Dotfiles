import { tool } from "@opencode-ai/plugin";
import type { Plugin, PluginInput } from "@opencode-ai/plugin";
import {
  StickyModelStore,
  flattenModelIDs,
  handleSubagentModelCommand,
  normalizeCommandName,
  childSessionTitle,
  resolveTaskModel,
  type ModelRef,
  type ProviderLike,
} from "./task-model.ts";

const PLUGIN_ID = "task-with-model";

/** Slash command (see `commands/subagent-model.md`) that manages the sticky default. */
const SUBAGENT_MODEL_COMMAND = "subagent-model";

/**
 * Shadows the built-in tool: a plugin tool with the same name takes
 * precedence. Same schema plus an optional `model` argument.
 */
const TASK_TOOL_ID = "task";

const TASK_DESCRIPTION = [
  "Delegate a task to a subagent.",
  "",
  "Fields:",
  "- subagent_type: the agent to run (any configured agent name).",
  '- description: a short (3-5 words) label for the task.',
  "- prompt: self-contained instructions for the subagent.",
  '- model (optional): "provider/model-id" (e.g. "abacate/performance"). Overrides the agent\'s pinned model for this call AND becomes the automatic default for later calls from the same session that omit it. Pass "reset" to clear the session default and go back to pinned models.',
  "- task_id (optional): resume a previous child session instead of creating one.",
  "- command (optional): the command that triggered this task (informational).",
  "",
  "If model is omitted, the session default (when set earlier) is used, otherwise the agent's pinned model, otherwise the calling session's model.",
  "",
  "Tip: the `/subagent-model <provider/model-id>` TUI command sets the session default without needing a task call.",
].join("\n");

type PluginClient = PluginInput["client"];

type SessionInfoLike = {
  id?: string;
  parentID?: string;
};

type AgentLike = {
  name: string;
  model?: { providerID: string; modelID: string };
  tools?: Record<string, boolean>;
};

type MessageLike = {
  info?: {
    role?: string;
    providerID?: string;
    modelID?: string;
  };
};

const asRecord = (value: unknown): Record<string, unknown> =>
  typeof value === "object" && value !== null ? (value as Record<string, unknown>) : {};

async function getSubagentDepthLimit(client: PluginClient): Promise<number> {
  try {
    const cfg = (await client.config.get({
      responseStyle: "data",
      throwOnError: true,
    })) as unknown as Record<string, unknown>;
    const limit = cfg["subagent_depth"];
    if (typeof limit === "number" && Number.isInteger(limit) && limit >= 0) return limit;
  } catch {
    // Fall through to the documented default.
  }
  return 1;
}

async function getSessionInfo(client: PluginClient, sessionID: string): Promise<SessionInfoLike | undefined> {
  try {
    const session = (await client.session.get({
      path: { id: sessionID },
      responseStyle: "data",
      throwOnError: true,
    })) as unknown as SessionInfoLike;
    return session;
  } catch {
    return undefined;
  }
}

/** Number of ancestors above the given session (mirrors the built-in task tool). */
async function sessionDepth(client: PluginClient, sessionID: string): Promise<number> {
  let depth = 0;
  let current: string | undefined = sessionID;
  // Bounded walk: depth can never usefully exceed limit + 1.
  for (let i = 0; i < 64 && current !== undefined; i++) {
    const info = await getSessionInfo(client, current);
    if (info?.parentID === undefined) break;
    depth++;
    current = info.parentID;
  }
  return depth;
}

async function listAgents(client: PluginClient): Promise<AgentLike[]> {
  const agents = (await client.app.agents({
    responseStyle: "data",
    throwOnError: true,
  })) as unknown as AgentLike[];
  return Array.isArray(agents) ? agents : [];
}

/** Model of the calling session, from its most recent assistant message. */
async function getParentModel(client: PluginClient, sessionID: string): Promise<ModelRef | undefined> {
  try {
    const messages = (await client.session.messages({
      path: { id: sessionID },
      query: { limit: 200 },
      responseStyle: "data",
      throwOnError: true,
    })) as unknown as MessageLike[];
    if (!Array.isArray(messages)) return undefined;
    for (let i = messages.length - 1; i >= 0; i--) {
      const info = messages[i]?.info;
      if (info?.role === "assistant" && typeof info.providerID === "string" && typeof info.modelID === "string") {
        return { providerID: info.providerID, modelID: info.modelID };
      }
    }
  } catch {
    // No usable parent model; the caller handles the fallback.
  }
  return undefined;
}

function textFromPromptResult(result: unknown): string {
  const parts = asRecord(result)["parts"];
  if (!Array.isArray(parts)) return "";
  for (let i = parts.length - 1; i >= 0; i--) {
    const part = asRecord(parts[i]);
    if (part["type"] === "text" && typeof part["text"] === "string") return part["text"] as string;
  }
  return "";
}

/** Available `provider/model-id` choices, for the `/subagent-model` status output. */
async function listAvailableModels(client: PluginClient): Promise<{ ids: string[]; total: number } | undefined> {
  try {
    const response = (await client.config.providers({
      responseStyle: "data",
      throwOnError: true,
    })) as unknown as { providers?: ProviderLike[] };
    if (!response || !Array.isArray(response.providers)) return undefined;
    return flattenModelIDs(response.providers);
  } catch {
    return undefined;
  }
}

const logToClient = (client: PluginClient) => {
  const log = async (level: "info" | "warn" | "error", message: string) => {
    try {
      await client.app.log({ body: { service: PLUGIN_ID, level, message } });
    } catch {
      // best-effort logging never breaks the tool
    }
  };
  return log;
};

export const TaskWithModelPlugin: Plugin = async ({ client }) => {
  const log = logToClient(client);
  // In-memory only: a new session ID has no entry (reverts to pins), and a
  // server restart clears everything. Never persisted to disk by design.
  const sticky = new StickyModelStore();

  return {
    event: async ({ event }) => {
      if (event.type !== "session.deleted") return;
      const properties = asRecord(event.properties);
      const info = asRecord(properties["info"]);
      const id = typeof info["id"] === "string" ? (info["id"] as string) : undefined;
      if (id) sticky.prune(id);
    },

    // Intercepts `/subagent-model` (registered via commands/subagent-model.md)
    // and applies it deterministically: no LLM reasoning needed. The agent
    // still gets a turn (this opencode version cannot skip it), so the
    // replacement parts tell it to acknowledge briefly.
    "command.execute.before": async (input, output) => {
      if (normalizeCommandName(input.command) !== SUBAGENT_MODEL_COMMAND) return;
      const args = input.arguments ?? "";
      await log("info", `/subagent-model invoked in session ${input.sessionID} with arguments "${args.trim()}"`);
      let text: string;
      try {
        // The model list is only needed for the bare status form.
        const availableModels = args.trim() === "" ? await listAvailableModels(client) : undefined;
        text = handleSubagentModelCommand({
          requested: args,
          sticky,
          sessionID: input.sessionID,
          ...(availableModels ? { availableModels } : {}),
        }).text;
      } catch (err) {
        text = `Could not set the sub-agent model: ${(err as Error).message} Acknowledge briefly.`;
      }
      // Mutate the array in place: the server keeps its own binding to the
      // original parts array, so reassigning `output.parts` is ignored.
      // (Verified against the session DB: reassignment left the template in
      // place while the hook itself ran.)
      output.parts.length = 0;
      (output.parts as unknown as Array<{ type: string; text: string }>).push({ type: "text", text });
    },

    tool: {
      [TASK_TOOL_ID]: tool({
        description: TASK_DESCRIPTION,
        args: {
          description: tool.schema.string().describe("A short (3-5 words) description of the task"),
          prompt: tool.schema.string().describe("The task for the agent to perform"),
          subagent_type: tool.schema.string().describe("The type of specialized agent to use for this task"),
          task_id: tool.schema
            .string()
            .optional()
            .describe("Resume a previous task instead of creating a fresh one"),
          command: tool.schema.string().optional().describe("The command that triggered this task"),
          model: tool.schema
            .string()
            .optional()
            .describe(
              'Optional "provider/model-id" override (e.g. "abacate/performance"). Becomes the session default for later calls. Pass "reset" to clear it.',
            ),
        },
        async execute(args, context) {
          const { description, prompt, subagent_type } = args;
          const requested = typeof args.model === "string" && args.model.trim() !== "" ? args.model : undefined;

          // Permission check mirrors the built-in task tool.
          await context.ask({
            permission: TASK_TOOL_ID,
            patterns: [subagent_type],
            always: ["*"],
            metadata: { description, subagent_type },
          });

          const depthLimit = await getSubagentDepthLimit(client);
          const depth = await sessionDepth(client, context.sessionID);
          if (depth >= depthLimit) {
            throw new Error(
              `Subagent depth limit reached (${depthLimit}). Increase "subagent_depth" to allow nested subagents.`,
            );
          }

          const agents = await listAgents(client);
          const agent = agents.find((a) => a.name === subagent_type);
          if (!agent) {
            throw new Error(`Unknown agent type: ${subagent_type} is not a valid agent type`);
          }
          const agentModel =
            agent.model && typeof agent.model.providerID === "string" && typeof agent.model.modelID === "string"
              ? { providerID: agent.model.providerID, modelID: agent.model.modelID }
              : undefined;

          // Only pay for the parent-model lookup when it can win.
          const needsParent = requested === undefined && sticky.get(context.sessionID) === undefined && agentModel === undefined;
          const parentModel = needsParent ? await getParentModel(client, context.sessionID) : undefined;

          const resolution = resolveTaskModel({
            requested,
            sticky,
            sessionID: context.sessionID,
            agentModel,
            parentModel,
          });

          if (resolution.kind === "explicit") {
            await log(
              "info",
              `session ${context.sessionID}: sticky subagent model set to ${resolution.model.providerID}/${resolution.model.modelID}`,
            );
          } else if (resolution.kind === "reset") {
            await log("info", `session ${context.sessionID}: sticky subagent model cleared (back to pins)`);
          }

          // Resume an existing child when asked, like the built-in tool.
          let childID: string | undefined;
          if (typeof args.task_id === "string" && args.task_id !== "") {
            const existing = await getSessionInfo(client, args.task_id);
            if (existing) childID = args.task_id;
          }
          if (childID === undefined) {
            const created = (await client.session.create({
              body: {
                parentID: context.sessionID,
                title: childSessionTitle(description, agent.name),
              },
              responseStyle: "data",
              throwOnError: true,
            })) as unknown as { id: string };
            if (!created || typeof created.id !== "string") {
              throw new Error("Failed to create subagent session");
            }
            childID = created.id;
          }

          // Child tool scoping approximates the built-in defaults (children
          // cannot spawn subagents or manage todos) unless the agent opts in.
          const childTools: Record<string, boolean> = {};
          if (agent.tools?.["task"] !== true) childTools["task"] = false;
          if (agent.tools?.["todowrite"] !== true) childTools["todowrite"] = false;

          const result = (await client.session.prompt({
            path: { id: childID },
            body: {
              agent: agent.name,
              ...(resolution.model
                ? { model: { providerID: resolution.model.providerID, modelID: resolution.model.modelID } }
                : {}),
              ...(Object.keys(childTools).length > 0 ? { tools: childTools } : {}),
              parts: [{ type: "text" as const, text: prompt }],
            },
            responseStyle: "data",
            throwOnError: true,
          })) as unknown;

          try {
            context.metadata({
              title: description,
              metadata: {
                parentSessionId: context.sessionID,
                sessionId: childID,
                ...(resolution.model
                  ? { model: { providerID: resolution.model.providerID, modelID: resolution.model.modelID } }
                  : {}),
                ...(typeof args.command === "string" && args.command !== "" ? { command: args.command } : {}),
              },
            });
          } catch {
            // Metadata is cosmetic; never fail the task for it.
          }

          return textFromPromptResult(result);
        },
      }),
    },
  };
};

export default {
  id: PLUGIN_ID,
  server: TaskWithModelPlugin,
};
