#!/usr/bin/env bash
# Install the plan-gate skill and its planner agent into ~/.claude.
# Idempotent. Backs up anything it would overwrite. Pass --dry-run to preview.
set -uo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

say() { printf '  %s\n' "$1"; }
run() { if [ "$DRY" -eq 1 ]; then say "would: $*"; else "$@"; fi; }

echo "plan-gate installer"
say "source: $SRC"
say "target: $DEST"
[ "$DRY" -eq 1 ] && say "MODE: dry run, nothing will change"
echo

if [ ! -d "$DEST" ]; then
  echo "ERROR: $DEST does not exist. Is Claude Code installed?" >&2
  exit 1
fi

# Back up anything already present.
for existing in "$DEST/skills/plan-gate" "$DEST/agents/plan-gate-planner.md"; do
  if [ -e "$existing" ]; then
    say "backing up $existing -> $existing.bak-$STAMP"
    run cp -r "$existing" "$existing.bak-$STAMP"
  fi
done

run mkdir -p "$DEST/skills" "$DEST/agents"
run rm -rf "$DEST/skills/plan-gate"
run cp -r "$SRC/skills/plan-gate" "$DEST/skills/plan-gate"
run cp "$SRC/agents/plan-gate-planner.md" "$DEST/agents/plan-gate-planner.md"
run chmod +x "$DEST/skills/plan-gate/scripts/preflight.sh" \
              "$DEST/skills/plan-gate/scripts/audit.sh"

echo
if [ "$DRY" -eq 1 ]; then
  echo "Dry run complete. Re-run without --dry-run to install."
  exit 0
fi

echo "Installed. Verifying:"
bash "$DEST/skills/plan-gate/scripts/audit.sh" 2>&1 | sed 's/^/  /'
echo
echo "IMPORTANT: agent files load at session start. Restart Claude Code"
echo "before plan-gate-planner is callable. The skill is available immediately."
