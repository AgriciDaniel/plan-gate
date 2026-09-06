#!/usr/bin/env bash
# Plan Gate: Lane B preconditions. Read-only, exits 1 if Codex cannot be gated safely.
set -uo pipefail

CODEX_SCRIPT="$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs"
fail=0

say() { printf '%-22s %s\n' "$1" "$2"; }

if [ -f /.flatpak-info ]; then
  say "sandbox:" "FLATPAK  <- Codex bubblewrap cannot nest here"
  say "" "Use 'flatpak-spawn --host' or move the task to Lane A."
  fail=1
else
  say "sandbox:" "host (ok)"
fi

if command -v bwrap >/dev/null 2>&1; then
  say "bubblewrap:" "$(command -v bwrap)"
else
  say "bubblewrap:" "MISSING  <- Codex sandbox cannot start"
  fail=1
fi

for bin in node codex; do
  if command -v "$bin" >/dev/null 2>&1; then
    say "$bin:" "$(command -v "$bin")"
  else
    say "$bin:" "MISSING"
    fail=1
  fi
done

if [ -f "$CODEX_SCRIPT" ]; then
  say "companion:" "found"
else
  say "companion:" "MISSING at $CODEX_SCRIPT"
  fail=1
fi

if [ -f "$HOME/.codex/config.toml" ]; then
  say "codex model:" "$(grep -oP '^model\s*=\s*"\K[^"]+' "$HOME/.codex/config.toml" 2>/dev/null || echo unset)"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "Lane B ready. Plan pass runs read-only (no --write)."
else
  echo "Lane B NOT safe. Fix the above, or use Lane A."
fi
exit "$fail"
