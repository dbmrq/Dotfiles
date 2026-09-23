import type { Plugin } from "@opencode-ai/plugin"
import type { Subprocess } from "bun"

const PLUGIN_ID = "caffeinate"

/**
 * Prevent the Mac from idle-sleeping while at least one OpenCode session is
 * active. We only hold `caffeinate -i`, so the display is still allowed to
 * sleep and the system can still sleep once every session is idle.
 *
 * Improvements over the reference implementation:
 *  - Detects unexpected `caffeinate` exits and restarts it while sessions are
 *    still busy.
 *  - Prevents duplicate start/stop races with a `starting` guard.
 *  - Cleans up the child process synchronously on process exit.
 *  - Survives logging failures without throwing.
 */
export const CaffeinatePlugin: Plugin = async ({ client }) => {
  // Only macOS ships `caffeinate`.
  if (process.platform !== "darwin") {
    return {}
  }

  const busySessions = new Set<string>()
  let child: Subprocess | null = null
  let starting = false
  let restartPending = false

  const log = async (level: "info" | "warn" | "error", message: string) => {
    try {
      await client.app.log({
        body: { service: PLUGIN_ID, level, message },
      })
    } catch {
      // Logging is best-effort; never let it break the plugin.
    }
  }

  const stopCaffeinate = async () => {
    if (!child) return
    child.kill()
    child = null
    await log("info", "allowing system idle sleep")
  }

  const startCaffeinate = async () => {
    if (child || starting) {
      // A start is already in flight; make sure we restart if it fails or if
      // the current process exits unexpectedly.
      restartPending = true
      return
    }

    starting = true
    restartPending = false

    try {
      const proc = Bun.spawn(["caffeinate", "-i"], {
        stdout: "ignore",
        stderr: "ignore",
        onExit: async (_proc, exitCode) => {
          // Ignore exits from a process we already replaced.
          if (child !== proc) return
          child = null
          starting = false

          if (busySessions.size > 0 || restartPending) {
            await log(
              "warn",
              `caffeinate exited unexpectedly (${exitCode}); restarting`,
            )
            await startCaffeinate()
          }
        },
      })

      child = proc
      await log("info", "preventing system idle sleep")
    } catch (err) {
      await log("error", `failed to start caffeinate: ${err}`)
    } finally {
      starting = false
      if (restartPending) {
        await startCaffeinate()
      }
    }
  }

  // Synchronous cleanup: the process is exiting so async handlers won't run.
  process.on("exit", () => {
    child?.kill()
  })

  return {
    event: async ({ event }) => {
      if (event.type !== "session.status") return

      const { sessionID, status } = event.properties
      const isIdle = status?.type === "idle"

      if (isIdle) {
        const removed = busySessions.delete(sessionID)
        if (removed && busySessions.size === 0) {
          await stopCaffeinate()
        }
      } else {
        const wasEmpty = busySessions.size === 0
        busySessions.add(sessionID)
        if (wasEmpty) {
          await startCaffeinate()
        }
      }
    },
  }
}

export default {
  id: PLUGIN_ID,
  server: CaffeinatePlugin,
}
