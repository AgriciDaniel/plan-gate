---
name: plan-gate
description: >
  Gate delegated work behind an orchestrator-reviewed plan. The cheap tier runs
  read-only first and returns a plan plus every open question, the orchestrator
  reviews and answers, and only then is execution released. Use when spawning a
  subagent on a cheaper model, when handing implementation to Codex, or when
  delegating multi-file, ambiguous, or parallel work. Trigger on /plan-gate,
  "plan first", "gate this", "have it plan before it executes", "plan then execute".
argument-hint: "<task> | claude | codex | preflight | audit"
---

# Plan Gate

Delegate the labour to a cheap tier. Keep the judgment on the orchestrator.
The gate is the checkpoint that stops a weak model executing confidently in the
wrong direction.

Routing (which tier, which pool, inline or delegated) belongs to `orchestrate`.
Read that first. This skill covers only what happens **after** you have decided
to delegate.

Every harness and Codex fact this skill relies on, with its evidence, is in
`reference/brain.md`. Check there before trusting a claim in this file.

## The loop

```
1. PLAN     cheap tier, write access removed, returns plan + all open questions
2. REVIEW   orchestrator answers the questions, accepts / revises / rejects
3. EXECUTE  write access released, plan is the contract
4. VERIFY   ground-truth check the cheap tier did not write
```

Step 1 is enforced by capability, never by instruction. A prompt that asks a
model not to write is not a gate.

## When to gate

Gate when **any** of `orchestrate`'s escalation triggers hold: more than 3 files,
root-causing rather than localizing, horizon beyond about an hour of human work,
ambiguous requirements, concurrency or subtle state, two retries already burned.

Add one trigger of this skill's own:

- **Two or more agents will touch overlapping surfaces.** Collect every plan
  before releasing any of them, so conflicts surface as plans rather than as
  merge damage.

## When not to gate

Single-file specified changes. Lookups, searches, reads. Anything where writing
the plan costs more than simply redoing the work. The gate is not free and
applying it universally is a tax on the majority of calls that are trivial.

### Measured, 2026-09-05

One A/B on a specified two-file task (add a `--json` mode to a 51-line script and
document it), identical fixtures, same Sonnet tier both arms:

| | tokens | tools | wall | result |
|---|---|---|---|---|
| Ungated | 76k | 14 | 162s | Working, text mode byte-identical, valid JSON, clean |
| Gated (plan only) | 26k | 8 | 119s | Plan with 4 open questions, wrote nothing |

The gated arm still needed review plus a full executor run on top of its 26k. That
executor was never run, so the true multiplier is **unmeasured**: the floor is 26k
plus review, and the executor is cheaper than 76k only if the plan removes enough
discovery to pay for itself. What the test does show is that the gate bought **no
better outcome** here. The ungated arm resolved all four open questions unaided,
and resolved one of them better than the planner's own recommendation.

The task was simply above the gate's threshold: specified, two files, no
discovery. That is the trigger list working, not an argument against it. But it
means the honest default is **do not gate**, and reach for it only on the triggers
above.

### The cheap alternative

On specified work, most of the gate's value comes from one line appended to an
ordinary delegation:

> Report anything you decided that the task did not specify.

In the same test that produced full, honest disclosure of five unrequested
decisions, at zero extra cost and with no second agent. Use this by default.
Escalate to the real gate only when a wrong decision is expensive to unwind.

## What the gate actually buys, per lane

| Lane | Enforced by | Saves quota | Context cost |
|---|---|---|---|
| A. Claude subagent | `tools:` allowlist | **No** | Executor rebuilds context |
| B. Codex | read-only OS sandbox | **Yes** | Executor rebuilds context |

Lane A does not save quota. On a subscription every Claude model bills the same
weekly pool, so a Sonnet planner is a quality control, not a cost control. Say so
honestly rather than claiming a saving that did not happen.

Lane B is the only lane that changes the billing pool. See
`~/.claude/skills/orchestrate/reference/codex-handoff.md`.

## Lane A: Claude subagent

Spawn `plan-gate-planner` (read-only: `Read`, `Grep`, `Glob`). Its plan comes back
as its final report.

```
Agent(subagent_type: "plan-gate-planner", prompt: "<task>\n\nReturn a plan in the
schema at ~/.claude/skills/plan-gate/reference/plan-schema.md")
```

Then review, then spawn a **separate** executor with the approved plan.

Two things that bite here:

- **`permissionMode: plan` is ignored in auto mode**, which is the configured
  default (`permissions.defaultMode: auto`). The frontmatter carries it anyway for
  manual-mode sessions, but the `tools:` allowlist is the part that actually holds.
  Run `/plan-gate audit` to check that allowlist has not drifted.
- **The planner cannot execute its own plan**, because it has no write tools.
  Resuming it does not help. A fresh executor rebuilds context, so the plan must
  carry enough detail to remove all rediscovery. That requirement is why the schema
  demands exact paths and anchors.

## Lane B: Codex

Full procedure and the environment precondition: `reference/lane-codex.md`.

Short form, from the orchestrator, not through `codex:codex-rescue` (that agent is
a strict forwarder and defaults to `--write`):

```bash
CODEX=~/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs

# 1. Plan pass. No --write, so the sandbox is read-only.
node "$CODEX" task "PLAN ONLY, do not edit anything. <task>. Return the schema at
  ~/.claude/skills/plan-gate/reference/plan-schema.md, and put every question you
  need answered in open_questions."

# 2. You review. Then release execution on a FRESH thread, passing the plan.
node "$CODEX" task --fresh --write "<approved plan in full, with answers>.
  Execute exactly that plan. Do not widen scope."
```

Both passes are **fresh threads**. `--resume-last --write` does not lift the
sandbox: Codex binds sandbox mode at thread creation, verified by live test on
2026-09-05. The approved plan must be passed to the executor as text, exactly as
on Lane A. Lane B still wins on billing pool and sandbox-grade enforcement, but
not on context cost.

Run `scripts/preflight.sh` first. Codex cannot start its own sandbox when Claude
Code is inside the VS Code Flatpak, and it can fail **silently with exit 0 and
empty results**. Treat an empty plan as a failure needing retry, never as a valid
answer.

## Persist the plan

Write the approved plan to a file before executing. Both lanes now hand work to a
**fresh** executor, so the plan is the only context that crosses the gate, and a
plan that lives only in the conversation does not survive compaction.

```
plans/<date>-<slug>/
  plan.md        the plan as returned
  decisions.md   the answers to open_questions, and who approved
```

Every comparable project does this: `.ac/plans/<slug>/plan.md` in
`anilcancakir/claude-code`, versioned `PLAN_v1.md` plus a separate `DECISIONS.md`
in `optim-plans`, `plan.md` plus `critique.md` in `plan-critique-skills`. Keeping
decisions in their own file matters: the plan is what was proposed, the decisions
are what was authorized, and conflating them loses the record of what you chose.

## Review

`reference/review-checklist.md`. Rejecting is the point. A gate that always
approves has paid the cost and bought nothing.

Answer every item in `open_questions` before approving. The planner gets one
handoff, not a conversation, so an unanswered question becomes an assumption.

## Verify

The plan is not the verification. Per `orchestrate`: a cheap tier is only safe
behind a check it did not write. Ordered strongest first: compile or type check,
lint, a reproduction written before the fix, the real suite, then a fresh-context
reviewer seeing only the diff.

## Honesty

- Do not claim the gate saved quota unless the work ran on Lane B.
- An empty or truncated Codex result is a failure, not an empty plan.
- One session proves nothing about whether the gate is worth its cost. Judge it on
  wall clock and merged work.

## Subcommands

- `/plan-gate <task>` run the full loop: plan, review, execute, verify
- `/plan-gate claude` run Lane A, the read-only `plan-gate-planner` subagent
- `/plan-gate codex` run Lane B, read-only plan pass then resume with `--write`
- `/plan-gate preflight` run `scripts/preflight.sh`, exit 1 means Lane B unsafe
- `/plan-gate audit` run `scripts/audit.sh`, checks the planner still cannot write
