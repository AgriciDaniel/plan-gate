# Lane B live test: the resume defect

Run 2026-09-05, on the host (not the VS Code Flatpak). Fixture: a 6-line
`greet.sh`. Task: add a `--upper` flag.

## Results

| Pass | Command | Result |
|---|---|---|
| Plan | `task` (no `--write`) | Plan returned, fixture **byte-for-byte pristine** |
| Execute | `task --resume-last --write` | **Refused.** Sandbox still read-only |
| Control | `task --fresh --write` | Wrote correctly, all 4 behaviours pass |

Codex on the resumed thread:

> I can't apply the approved change because this session's filesystem permissions
> are read-only and escalation is disabled. No files were changed.

The thread resumed correctly (same id `01a072d1-f539-...`). Only the permission
upgrade failed.

## Conclusion

**Codex binds sandbox mode at thread creation, not per turn.** A thread created
read-only can never be upgraded. The companion does pass `sandbox` on every turn
(`codex-companion.mjs:491`), so this is Codex app-server behaviour, not a bug in
the bridge. The `--fresh --write` control isolates the cause.

## What this falsified

The original design claimed `--resume-last` preserved context across the gate, so
Lane B was the cheap lane. **That was wrong.** Both passes must be fresh threads
and the approved plan must be passed to the executor as text, exactly as on
Lane A.

Corrected consequence: Lane A and Lane B have the **same context cost**. Lane B's
remaining advantages are narrower but real: it bills a different pool, and its
read-only pass is enforced by an OS sandbox rather than a tool allowlist.

## What survived

The read-only plan pass works exactly as designed and left the fixture untouched.
The gate itself is sound. Only the release step needed redesigning.
