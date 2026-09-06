# Lane B: Codex

The only lane that changes the billing pool, and the only one where the gate is
enforced by a real sandbox rather than a tool allowlist.

```bash
CODEX=~/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs
```

## Precondition: run preflight

```bash
bash ~/.claude/skills/plan-gate/scripts/preflight.sh
```

Codex launches its own bubblewrap sandbox. Bubblewrap cannot nest, so when Claude
Code runs inside the VS Code Flatpak the sandbox fails **before any command runs**
and Codex returns empty results while exiting 0. A silent failure that looks like
a valid empty plan.

If preflight reports Flatpak, either run Codex on the host with
`flatpak-spawn --host`, or move the task to Lane A. Do not paper over it by
reaching for `--dangerously-bypass-approvals-and-sandbox`; that removes the very
sandbox this gate depends on, and it needs explicit authorization from Daniel
first. See `[[codex-flatpak-sandbox]]` and `[[codex-sandbox-needs-host-spawn]]`.

## 1. Plan pass

No `--write`. `codex-companion.mjs:491` sets `sandbox: request.write ?
"workspace-write" : "read-only"`, so omitting the flag is what enforces the gate.

```bash
node "$CODEX" task "PLAN ONLY. Do not edit any file.

<task>

Return a plan in the schema at
~/.claude/skills/plan-gate/reference/plan-schema.md. Put every question you need
answered into open_questions; you get one handoff, not a conversation."
```

Foreground is the default and blocks until done, which is what you want. Add
`--background` only for a long task, then poll with `status` and `result`.

Model and effort:

- Leave `--model` unset to inherit `~/.codex/config.toml` (currently
  `gpt-6-astra`). Only `spark` is aliased by the runtime; every other value is
  passed through as a raw model ID, so the Codex UI tier names (Terra, Luna, Sol)
  will not resolve on their own. Pass a real ID or leave it unset.
- `--effort` accepts `none`, `minimal`, `low`, `medium`, `high`, `xhigh`. Planning
  is where effort earns its cost, so do not reflexively downshift the plan pass.
  Downshift the execution pass instead, once the plan has removed the ambiguity.

## 2. Review

`reference/review-checklist.md`.

## 3. Execute

**`--resume-last --write` does not work.** Tested live 2026-09-05: the thread
resumes correctly, but the sandbox stays read-only and Codex reports "this
session's filesystem permissions are read-only and escalation is disabled".
Codex binds sandbox mode at **thread creation**, so a thread created read-only
can never be upgraded. A fresh `--write` thread on the same task writes without
complaint, which isolates the cause.

So the execute pass is a **fresh thread**, handed the approved plan as text:

```bash
node "$CODEX" task --cwd <dir> --fresh --write "<approved plan in full,
including the answers to its open questions>

Execute exactly this. Do not widen scope. Do not touch <excluded>."
```

Consequence: context does **not** survive the gate. Lane B has the same context
cost as Lane A, so the plan must carry every path, anchor and constraint the
executor needs. Lane B's remaining advantages are still real but narrower: it
bills a different pool, and its read-only pass is enforced by an OS sandbox
rather than a tool allowlist.

## 4. Verify

On the orchestrator, or with a fresh Codex review pass that did not write the
change. Never accept the executing thread's own claim of success.

## Failure modes to treat as failures

- Empty result with exit 0. Sandbox failure. Retry, do not accept.
- `files_reviewed: 0` or similar zero-coverage output. Same.
- The execution pass returns a plan instead of a diff, or says permissions are
  read-only. You resumed a read-only thread instead of starting a fresh `--write`
  one. Sandbox mode cannot be upgraded on an existing thread.
