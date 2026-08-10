#!/usr/bin/env bash
#
# switch-models.sh — switch OpenCode's per-agent model pins between a "free"
# and a "paid" profile, then optionally restart OpenCode.
#
# ==================================================================
#  WHY THIS EXISTS
# ==================================================================
# OpenCode config pins do NOT hot-reload in 1.18.10. Changing
# opencode.jsonc requires editing the file and restarting OpenCode.
# This script makes profile switching a single command.
#
# ==================================================================
#  THE PAID / FREE SPLIT (design rationale)
# ==================================================================
#   * general / explore / implement  -> SUBAGENTS. Always pinned to a model
#     so they never accidentally run on a paid model.
#   * orchestrate / plan             -> INTENTIONALLY UNPINNED. They inherit
#     the session/global model, so you control what they run on via the TUI
#     model picker or via the top-level "model" setting.
#
#   - free profile:
#       top-level "model" = opencode/deepseek-v4-flash-free
#       general/explore/implement pinned to opencode/deepseek-v4-flash-free
#       orchestrate/plan unpinned (inherit the free global)
#
#   - paid profile:
#       top-level "model" = $DEFAULT_PAID_MODEL (or a custom provider/model)
#       general/explore/implement pinned to that same paid model
#       orchestrate/plan unpinned (inherit the paid global, so a new session
#       runs orchestrate/plan on paid while subagents stay pinned)
#
#   Everything else in opencode.jsonc ($schema, permission, subagent_depth,
#   plugin, ...) is preserved byte-for-byte.
#
# ==================================================================
#  USAGE
# ==================================================================
#   switch-models.sh                          -> free profile (default)
#   switch-models.sh free                     -> free profile
#   switch-models.sh paid                     -> paid profile ($DEFAULT_PAID_MODEL)
#   switch-models.sh paid anthropic/claude-opus-4   -> custom paid model
#   switch-models.sh status                   -> print current pins, change nothing
#   switch-models.sh anything-unknown         -> same as status
#   switch-models.sh --help | -h              -> this help
#
#   Add --restart to free/paid to kill and relaunch the OpenCode TUI after
#   switching:   switch-models.sh paid --restart
# ==================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/opencode.jsonc"

# -- CHANGE THIS DEFAULT IF YOU WANT A DIFFERENT PAID MODEL ---------------
DEFAULT_PAID_MODEL="anthropic/claude-opus-4"
FREE_MODEL="opencode/deepseek-v4-flash-free"
# -------------------------------------------------------------------------

usage() {
  cat <<'EOF'
switch-models.sh — switch OpenCode per-agent model pins between paid/free profiles.

USAGE
  switch-models.sh                          free profile (default)
  switch-models.sh free                     free profile
  switch-models.sh paid                     paid profile (DEFAULT_PAID_MODEL)
  switch-models.sh paid <provider>/<model>  paid profile with a custom model
  switch-models.sh status                   show current pins, change nothing
  switch-models.sh --restart ...            also kill + relaunch the OpenCode TUI
  switch-models.sh --help | -h              this help

PROFILES
  free: top-level "model" and general/explore/implement all pinned to
        opencode/deepseek-v4-flash-free; orchestrate/plan stay unpinned.
  paid: top-level "model" and general/explore/implement pinned to
        ${DEFAULT_PAID_MODEL} (or your custom model); orchestrate/plan stay
        unpinned and inherit the paid global.

  Subagents (general/explore/implement) are ALWAYS pinned so they never
  accidentally burn paid tokens. orchestrate/plan are intentionally unpinned
  so they follow the session model (switchable via the TUI model picker).
  Config file edited: ${CONFIG}
EOF
}

# ---- argument parsing ---------------------------------------------------
RESTART=0
MODE_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --restart) RESTART=1 ;;
    -h|--help|help) usage; exit 0 ;;
    *) MODE_ARGS+=("$arg") ;;
  esac
done

MODE="free"
MODEL=""
if [[ ${#MODE_ARGS[@]} -ge 1 ]]; then
  case "${MODE_ARGS[0]}" in
    free|paid|status) MODE="${MODE_ARGS[0]}";;
    *) MODE="status";;
  esac
  if [[ ${#MODE_ARGS[@]} -ge 2 ]]; then
    MODEL="${MODE_ARGS[1]}"
  fi
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "error: config not found: $CONFIG" >&2
  exit 1
fi

# ---- shared python editor/status tool -----------------------------------
# args: cfg_path mode arg_model free_model default_paid
run_python() {
  python3 - "$CONFIG" "$MODE" "$MODEL" "$FREE_MODEL" "$DEFAULT_PAID_MODEL" <<'PYEOF'
import re, json, sys

cfg_path, mode, arg_model, free_model, default_paid = sys.argv[1:6]
mode = mode.lower()

def load_jsonc(t):
    # stateful strip: removes // and /* */ comments and trailing commas,
    # but never touches content inside string literals (e.g. $schema URL).
    out = []
    i = 0
    n = len(t)
    in_str = in_line = in_block = False
    while i < n:
        c = t[i]
        nxt = t[i + 1] if i + 1 < n else ""
        if in_line:
            if c == "\n":
                in_line = False
                out.append(c)
            i += 1
            continue
        if in_block:
            if c == "*" and nxt == "/":
                in_block = False
                i += 2
                continue
            if c == "\n":
                out.append(c)
            i += 1
            continue
        if in_str:
            out.append(c)
            if c == "\\" and nxt:
                out.append(nxt)
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and nxt == "/":
            in_line = True
            i += 2
            continue
        if c == "/" and nxt == "*":
            in_block = True
            i += 2
            continue
        if c == ",":
            j = i + 1
            while j < n and t[j] in " \t\r\n":
                j += 1
            if j < n and t[j] in "}]":
                i += 1  # trailing comma -> drop
                continue
            out.append(c)
            i += 1
            continue
        out.append(c)
        i += 1
    return json.loads("".join(out))

with open(cfg_path) as f:
    text = f.read()

try:
    data = load_jsonc(text)
except Exception as e:
    sys.stderr.write("error: %s is not valid JSON: %s\n" % (cfg_path, e))
    sys.exit(1)

if mode == "status":
    print("global model      : %s" % data.get("model", "(not set)"))
    agents = data.get("agent") or {}
    for name in ("general", "explore", "implement", "orchestrate", "plan"):
        a = agents.get(name)
        if a is None:
            print("agent %-13s: (absent)" % name)
        else:
            print("agent %-13s: %s" % (name, a.get("model", "(unpinned - inherits global)")))
    sys.exit(0)

if mode == "free":
    target = free_model
elif mode == "paid":
    target = arg_model if arg_model else default_paid
else:
    sys.stderr.write("error: unknown mode %r\n" % mode)
    sys.exit(2)

if not target or "/" not in target:
    sys.stderr.write("error: invalid model %r (expected provider/model, e.g. anthropic/claude-opus-4)\n" % target)
    sys.exit(1)

target_json = '"%s"' % target
PINNED = ("general", "explore", "implement")
UNPINNED = ("orchestrate", "plan")

lines = text.split("\n")
n = len(lines)
out = []
i = 0
depth = 0
top_model_seen = False
agent_processed = False

while i < n:
    ln = lines[i]
    stripped = ln.strip()
    body = stripped.rstrip(",").rstrip()

    if depth == 1 and body.startswith('"model"'):
        # top-level (global) model line: replace only the quoted value so any
        # trailing comma / whitespace stays intact.
        out.append(re.sub(r'("model"\s*:\s*)"(?:[^"\\]|\\.)*"',
                          lambda mo: mo.group(1) + target_json, ln, count=1))
        top_model_seen = True
        i += 1
        continue

    if depth == 1 and body.startswith('"agent"') and body.endswith("{"):
        # ----- rebuild the agent block (preserving unknown agent keys) -----
        agent_processed = True
        out.append(ln)
        depth += ln.count("{") - ln.count("}")
        i += 1
        inner = []
        while i < n and depth > 1:
            inner.append(lines[i])
            depth += lines[i].count("{") - lines[i].count("}")
            i += 1
        closing = "  }"
        if inner and inner[-1].strip().startswith("}"):
            closing = inner.pop()

        stack = []                       # names of currently open agent sub-blocks
        pinned_model_seen = set()        # pinned agents whose model line we set
        block_open_index = {}            # insertion index for model line right after a sub-block's "{"
        missing_blocks = []
        j = 0
        while j < len(inner):
            lin = inner[j]
            s2 = lin.strip()
            b2 = s2.rstrip(",").rstrip()
            if b2.endswith("{") and b2.startswith('"') and ":" in b2:
                name = b2[1:b2.index('"', 1)]
                stack.append(name)
                out.append(lin)
                block_open_index[name] = len(out)
            elif b2.startswith('"model"'):
                if stack and stack[-1] in UNPINNED:
                    pass                       # drop unpinned agent's model line
                elif stack and stack[-1] in PINNED:
                    out.append(re.sub(r'("model"\s*:\s*)"(?:[^"\\]|\\.)*"',
                                      lambda mo: mo.group(1) + target_json, lin, count=1))
                    pinned_model_seen.add(stack[-1])
                else:
                    out.append(lin)             # keep unrelated model line
            elif b2.startswith("}"):
                for _ in range(lin.count("}")):
                    if stack:
                        stack.pop()
                out.append(lin)
            else:
                out.append(lin)
            j += 1

        # ensure each pinned agent actually carries the model pin
        for name in PINNED:
            if name in pinned_model_seen:
                continue
            if name in block_open_index:
                idx = block_open_index[name]
                open_line = out[idx - 1]
                inner_indent = open_line[: len(open_line) - len(open_line.lstrip())] + "  "
                model_line = '%s"model": %s' % (inner_indent, target_json)
                out.insert(idx, model_line)
                # a comma is needed if another key follows before the close brace
                if idx + 1 < len(out) and not out[idx + 1].lstrip().startswith("}"):
                    out[idx] = model_line + ","
            else:
                missing_blocks.append(name)
        if missing_blocks:
            if out and out[-1].rstrip().endswith("}"):
                out[-1] = out[-1].rstrip() + ","
            for k, name in enumerate(missing_blocks):
                out.append('    "%s": {' % name)
                out.append('      "model": %s' % target_json)
                out.append('    },' if k < len(missing_blocks) - 1 else '    }')
        out.append(closing)
        continue

    out.append(ln)
    depth += ln.count("{") - ln.count("}")
    i += 1

# ----- fallbacks for a config that lacks top-level model / agent block -----
if not top_model_seen:
    insert_at = None
    for k, l in enumerate(out):
        if l.strip() == "{":
            insert_at = k + 1
            break
    if insert_at is None:
        sys.stderr.write("error: could not locate top-level object\n")
        sys.exit(1)
    out.insert(insert_at, '  "model": %s,' % target_json)

if not agent_processed:
    insert_at = None
    for k, l in enumerate(out):
        if l.strip() == "{":
            insert_at = k + 1
            break
    if insert_at is None:
        sys.stderr.write("error: could not locate top-level object\n")
        sys.exit(1)
    agent_block = ['  "agent": {']
    for k, name in enumerate(PINNED):
        agent_block.append('    "%s": {' % name)
        agent_block.append('      "model": %s' % target_json)
        agent_block.append('    },' if k < len(PINNED) - 1 else '    }')
    agent_block.append('  },')
    out[insert_at:insert_at] = agent_block

# ----- validate BEFORE writing; abort (file untouched) if broken -----
result = "\n".join(out)
try:
    load_jsonc(result)
except Exception as e:
    sys.stderr.write("error: edited config is not valid JSON: %s\n" % e)
    sys.stderr.write("aborting; %s left unchanged\n" % cfg_path)
    sys.exit(1)

with open(cfg_path, "w") as f:
    f.write(result)
sys.exit(0)
PYEOF
}

# ---- status mode: just print, never modify -------------------------------
if [[ "$MODE" == "status" ]]; then
  run_python
  exit 0
fi

# ---- apply the profile ----------------------------------------------------
echo "== switch-models.sh: applying '$MODE' profile =="
if [[ "$MODE" == "paid" ]]; then
  echo "target model: ${MODEL:-$DEFAULT_PAID_MODEL}"
else
  echo "target model: $FREE_MODEL"
fi

run_python

# strict JSON check (works because we keep the file comment-free)
python3 -c "import json,sys; json.load(open(sys.argv[1])); print('validated: plain json.load OK')" "$CONFIG"

echo ""
echo "New effective pins:"
bash "$SCRIPT_DIR/$(basename "$0")" status

echo ""
echo "Config pins do not hot-reload — restart OpenCode (or run: opencode)."
echo "To do it in one command next time: switch-models.sh $MODE --restart"

if [[ "$RESTART" -eq 1 ]]; then
  echo ""
  echo "== restarting OpenCode =="
  echo "warning: killing any running 'opencode' process (pkill -x opencode)."
  echo "         If you ran this from inside an OpenCode session, that session dies here."
  pkill -x opencode || echo "note: no 'opencode' process was running."
  sleep 1
  nohup opencode >/dev/null 2>&1 &
  echo "relaunched: nohup opencode &"
fi
