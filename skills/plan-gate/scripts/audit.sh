#!/usr/bin/env bash
# Plan Gate: verify Lane A enforcement has not silently regressed.
# The tools: allowlist is the ONLY thing holding the gate under auto mode,
# because permissionMode is ignored there. Nothing else notices if it drifts.
set -uo pipefail

AGENT="${1:-$HOME/.claude/agents/plan-gate-planner.md}"

python3 - "$AGENT" <<'PY'
import re, sys
p = sys.argv[1]
try:
    s = open(p).read()
except OSError as e:
    print(f"FAIL  cannot read {p}: {e}"); sys.exit(1)

m = re.match(r"^---\n(.*?)\n---\n", s, re.S)
if not m:
    print(f"FAIL  {p}: no YAML frontmatter"); sys.exit(1)
try:
    import yaml
    fm = yaml.safe_load(m.group(1))
except ImportError:
    print("SKIP  pyyaml not available"); sys.exit(0)
except Exception as e:
    print(f"FAIL  frontmatter does not parse: {e}"); sys.exit(1)

fail = 0
tools = fm.get("tools")

if tools is None:
    print("FAIL  no tools: allowlist. Agent inherits EVERY tool, gate is open.")
    fail = 1
else:
    # Bash writes files, so it counts as mutating for this gate.
    mutating = {"Write", "Edit", "MultiEdit", "NotebookEdit", "Bash"}
    found = sorted(mutating & set(tools))
    if found:
        print(f"FAIL  mutating tools present: {', '.join(found)}")
        fail = 1
    else:
        print(f"ok    tools allowlist read-only: {', '.join(tools)}")

if fm.get("permissionMode") != "plan":
    print("warn  permissionMode is not 'plan' (inert under auto mode, but keep it)")

known = {"name","description","tools","disallowedTools","model","permissionMode",
         "maxTurns","skills","mcpServers","hooks","memory","background","effort",
         "isolation","color","initialPrompt","experimental"}
unknown = set(fm) - known
if unknown:
    print(f"warn  unrecognized frontmatter keys (silently ignored at load): {unknown}")

print("\nLane A enforcement intact." if not fail else "\nLane A GATE IS OPEN. Fix before delegating.")
sys.exit(fail)
PY
