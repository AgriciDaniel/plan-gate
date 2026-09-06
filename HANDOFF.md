# Handoff

Everything needed to pick this up cold. Built 2026-09-05, researched and corrected
2026-09-06.

## How to actually use it

Three levels. Pick the cheapest one that fits, the default is the first.

**1. No gate.** Most delegation. Specified work, single file, lookups, anything
where writing a plan costs more than redoing the work.

**2. One line.** The default for ordinary delegation. Append to the prompt:

> Report anything you decided that the task did not specify.

Measured: this produced honest disclosure of five unrequested decisions at zero
extra cost. Use this far more often than the full gate.

**3. The full gate.** Only on `orchestrate`'s escalation triggers: more than 3
files, root-causing rather than localizing, over about an hour of work, ambiguous
requirements, subtle state, two retries burned, or two agents on overlapping
surfaces.

```
/plan-gate <task>       full loop
/plan-gate claude       Lane A, read-only planner subagent
/plan-gate codex        Lane B, read-only pass then a fresh --write pass
/plan-gate preflight    is Lane B safe here
/plan-gate audit        can the planner still not write
```

## Run this after any change to the planner agent

```bash
~/.claude/skills/plan-gate/scripts/audit.sh
```

The `tools:` allowlist is the only thing holding Lane A shut. Nothing else notices
if it drifts. Exit 1 means the gate is open.

## Before any Codex work from VS Code

```bash
~/.claude/skills/plan-gate/scripts/preflight.sh
```

Codex's bubblewrap sandbox cannot nest inside the VS Code Flatpak. It fails before
any command runs and returns empty results **while exiting 0**, which reads as a
valid empty plan. Treat an empty plan as a failure needing retry, never an answer.

## The three facts that cost the most to learn

1. **`permissionMode: plan` fails open**, under auto, `acceptEdits` and
   `bypassPermissions`. Restrict with `tools:`, and exclude `Bash`, which writes.
2. **Codex cannot change sandbox mode on an existing thread.** Plan and execute
   are two fresh threads, and the plan must carry the full context. Upstream:
   openai/codex#33974.
3. **Agent files load at session start.** Skills hot-load, agents do not. Writing
   an agent mid-session gives "Agent type not found" until restart.

## Still open

**Codex pricing in `~/.claude/skills/orchestrate/reference/tiers.md` is stale.**
It prices a 5.6 line (Sol / Terra / Luna) while your `~/.codex/config.toml` runs
`gpt-6-astra`, which is absent from the table. Those tier names are Codex UI
labels and will not resolve as `--model` values; only `spark` is aliased in
`codex-companion.mjs:72`.

The file carries a dated caveat saying exactly this. The numbers were left alone
on purpose rather than rewritten from memory. To close it: get current OpenAI
pricing from a primary source and replace the table, or delete the prices and keep
only the routing advice.

## What was deliberately not built

- **A full execution engine.** `optim-plans` removed theirs on purpose, and our
  A/B points the same way: planning quality matters more than the gate.
- **Checkpoint commits per wave.** Good idea from `anilcancakir/claude-code`, but
  it presumes a git repo and a wave executor this does not have.
- **Human-only approval enforcement.** Named honestly in the review checklist
  instead. The orchestrator approving a plan is a model approving a model, so on
  anything hard to unwind, a human approves.

## Where things live

| | |
|---|---|
| Installed | `~/.claude/skills/plan-gate/`, `~/.claude/agents/plan-gate-planner.md` |
| This bundle | portable copy, `./install.sh` to redeploy |
| Facts and citations | `skills/plan-gate/reference/brain.md` |
| Test evidence | `evidence/` |
| Session findings | `~/.claude/projects/-var-home-agricidaniel-Desktop-best-of-the-best-ever/memory/` |
