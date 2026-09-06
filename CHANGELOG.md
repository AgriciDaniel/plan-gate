# Changelog

## 0.1.0 - 2026-09-06

First working version.

- Read-only planner subagent enforced by a `tools:` allowlist, which holds in
  every parent permission mode. `permissionMode: plan` does not: it is ignored
  under auto, `acceptEdits`, and `bypassPermissions`.
- Codex lane gated by the read-only OS sandbox, with `preflight.sh` to check the
  environment can actually run it.
- `audit.sh` to catch the planner's allowlist silently drifting open.
- Ten-field plan schema, including frozen `done_when` completion criteria.
- Review checklist with explicit reject conditions.
- Evidence for every claim, including the two findings that argue against using
  the gate by default.

Corrected before release, both found by live testing rather than review:

- Codex cannot change sandbox mode on an existing thread, so
  `--resume-last --write` does not work. Both passes are fresh threads.
- The `approach` field was inducing planners to invent rejected alternatives they
  had never considered. Now it accepts "no real alternative".
