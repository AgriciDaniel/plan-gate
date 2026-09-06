# Plan Gate brain

Verified facts this skill depends on, each with the evidence that established it.
Claims are separated by how they were checked. Re-verify anything marked with a
version or a date before relying on it in a later release.

Routing economics live in `orchestrate` and are not duplicated here. See
`~/.claude/skills/orchestrate/SKILL.md` and `reference/codex-handoff.md`.

## Harness: subagents and permission modes

**`permissionMode` is a real subagent frontmatter field.** Values: `default`,
`acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, `manual` (alias for
`default`, needs v2.1.200+). Ignored for plugin subagents.
`code.claude.com/docs/en/sub-agents.md`, frontmatter table. Verified 2026-09-05.

**It is ignored in three parent modes, not one.** From `sub-agents.md`, the
`permissionMode` section, verified 2026-09-06: "If the parent uses
`bypassPermissions` or `acceptEdits`, this takes precedence and can't be
overridden. If the parent uses auto mode, the subagent inherits auto mode and any
`permissionMode` in its frontmatter is ignored: the classifier evaluates the
subagent's tool calls with the same block and allow rules as the parent session."

Daniel runs `permissions.defaultMode: auto`, so this is the normal case. But the
gate also fails open under `acceptEdits` and `bypassPermissions`, which makes
`permissionMode: plan` unreliable in the majority of realistic parent states.

**Consequence: a `tools:` allowlist is the only enforcement that holds.** Tool
availability is structural, not mode-dependent. `Bash` must be excluded too, since
it writes files. Checked by `scripts/audit.sh`.

**Subagents inherit the parent's mode.** Binary string, Claude Code 2.1.261:
"Subagents inherit the parent session's permission mode; agent-definition
frontmatter may override it." `bypassPermissions` is additionally refused outside
a contained no-internet environment.

**Subagent `model:` is Anthropic-only.** Aliases (`sonnet`, `opus`, `haiku`,
`fable`), a full Claude model ID, or `inherit`. No Gemini or OpenAI routing.
`code.claude.com/docs/en/sub-agents.md`. So a non-Claude model reaches you only as
an external process behind a Bash wrapper, which `permissionMode` cannot govern.

**Agent files load at session start; skills hot-load.** Writing
`~/.claude/agents/*.md` mid-session gives "Agent type not found" until restart.
Observed 2026-09-05 on 2.1.261. Unknown frontmatter keys are silently ignored at
load, so a typo'd field fails open with no error.

**`SubagentStart` hook exists** (2.1.261). Input JSON carries `agent_id` and
`agent_type`; exit 0 returns `additionalContext` shown to the subagent; exit 2
shows stderr to the user. It injects context, it does not hard-block. In auto mode
the classifier evaluates the task description at spawn time, which is what blocks.
`code.claude.com/docs/en/hooks.md`.

## Codex bridge

**The plan pass is enforced by sandbox, not by prompt.**
`codex-companion.mjs:491`: `sandbox: request.write ? "workspace-write" :
"read-only"`. Omitting `--write` is the gate.

**`task` flags**: `--background`, `--write`, `--resume-last|--resume|--fresh`,
`--model`, `--effort`, `--cwd`, `--prompt-file`, `--json`. Effort accepts `none`,
`minimal`, `low`, `medium`, `high`, `xhigh`. `codex-companion.mjs:82`, `:765`.

**`--resume-last --write` does NOT lift the sandbox.** Live test 2026-09-05: the
thread resumed (same id) but stayed read-only, Codex reporting "filesystem
permissions are read-only and escalation is disabled". A fresh `--write` thread on
the identical task wrote successfully, isolating the cause: Codex binds sandbox
mode at thread creation. The companion passes `sandbox` per turn
(`codex-companion.mjs:491`), but the Codex app server ignores it on resume.
Consequence: both Lane B passes are fresh threads, and context does not survive
the gate. This falsified the original design claim that Lane B was the cheap lane.

**Confirmed upstream, not a local quirk.** openai/codex issue #33974, "Allow
switching sandbox/approval mode within an active session": sandbox mode and
approval policy "have to be decided at process start via CLI flags or config. Once
a codex session is running, there is no way to switch modes without exiting and
restarting the process, which loses the entire in-memory conversation context."
The proposed `codex session set-sandbox <id>` fix is not implemented. So the
fresh-thread design is correct and unavoidable, not a workaround.
https://github.com/openai/codex/issues/33974

**Only `spark` is aliased.** `MODEL_ALIASES` at `codex-companion.mjs:72` maps
`spark` to `gpt-5.3-codex-spark`; every other `--model` value passes through as a
raw ID. The Codex UI tier names (Terra, Luna, Sol) will not resolve. Local default
is `model = "gpt-6-astra"` in `~/.codex/config.toml`. Checked 2026-09-05. The 5.6
tier table in `orchestrate/reference/tiers.md` looks stale against this.

**Codex's sandbox cannot nest inside the VS Code Flatpak.** bubblewrap will not
run nested, so the sandbox fails before any command runs and Codex returns empty
results **while exiting 0**. A silent failure that reads as a valid empty plan.
From Daniel's own sessions, 2026-07-09 and later. Treat an empty plan as a failure
needing retry. `scripts/preflight.sh` detects this. Cross-links:
`[[codex-flatpak-sandbox]]`, `[[codex-sandbox-needs-host-spawn]]`,
`[[codex-cannot-write-in-flatpak-sandbox]]`.

**Do not route the gate through `codex:codex-rescue`.** That agent is a strict
single-call forwarder and defaults to `--write`. Call the companion directly.

## Measured, 2026-09-05

One A/B, identical fixtures, Sonnet both arms, on a specified two-file task.

| | tokens | tools | wall | outcome |
|---|---|---|---|---|
| Ungated | 76k | 14 | 162s | Correct, text mode byte-identical, valid JSON |
| Gated, plan only | 26k | 8 | 119s | Plan, 4 open questions, wrote nothing |

- The read-only allowlist held: the gated fixture was byte-for-byte pristine.
- The gate bought no better outcome on a specified task. The unguided arm resolved
  all four open questions, one of them **better** than the planner recommended.
- Executor cost for the gated arm was never measured, so the true multiplier is
  unknown. Do not quote one.
- Both planners manufactured fake rejected alternatives when `approach` demanded
  one. The control agent said so itself: "I invented two alternatives here that I
  never seriously considered." A schema field can induce dishonesty.
- n=1 per arm. Per `orchestrate`: "Single runs lie in both directions."

### Lane B live test, 2026-09-05

First end-to-end run of Lane B, on a 6-line fixture script.

| Pass | Command | Result |
|---|---|---|
| Plan | `task` (no `--write`) | Plan returned, fixture **byte-for-byte pristine** |
| Execute | `task --resume-last --write` | **Refused**, sandbox still read-only |
| Control | `task --fresh --write` | Wrote correctly, all 4 behaviours pass |

The read-only pass works exactly as designed and is genuinely enforced. The
resume-based execute pass does not work at all. Corrected design: both passes are
fresh threads, plan passed as text.

## Standing cautions

- Never claim the gate saved quota unless the work ran on Lane B. Every Claude
  model bills the same subscription pool.
- A plan is not verification. Per `orchestrate`, a cheap tier is only safe behind a
  check it did not write.
- An empty or truncated Codex result is a failure, never an empty plan.

## Prior art, surveyed 2026-09-06

Three projects solve an overlapping problem. Worth reading before extending this.

**anilcancakir/claude-code** is the closest to this design and reached the same
core conclusion independently: it enforces read-only review by **capability
restriction, not permission modes**. Its `auto-verifier` "holds no `Edit`, `Write`
or `Agent`" tool. It also routes per step across haiku/sonnet/opus, persists plans
to `.ac/plans/<slug>/plan.md`, and runs an adversarial chain (plan-reviewer reads
the plan cold, code-reviewer sees only the diff). Two ideas worth stealing:
**frozen completion criteria** (it hashes the definition of "done" before starting,
which directly attacks the scope creep our A/B measured) and **checkpoint commits
per wave** for rollback granularity.
https://github.com/anilcancakir/claude-code

**Optim-Agent/optim-plans** gates on an explicit human handoff and, critically,
"`Auto-complete` cannot approve this native handoff, only human choice is
permitted." It versions plans (`PLAN_v1.md`, `PLAN_v2.md`), keeps `DECISIONS.md`
separate, and writes an append-only event log to `.git/optim-plans/`. It uses
hooks as "defense in depth... they inject context and deny out-of-scope writes".
It supports Codex as well as Claude. Note that v0.3.0 deliberately **removed** its
execution engine to focus on planning quality.
https://github.com/Optim-Agent/optim-plans

**serbanghita/plan-critique-skills** inverts the usual model: "You write and own
the plan. The AI acts as an adversarial reviewer." Its critique step grades each
finding `CONFIRMED` or `UNVERIFIED`, which is a better evidence discipline than
our checklist currently demands. Prompt-based, no mechanical enforcement.
https://github.com/serbanghita/plan-critique-skills

**What they all do that we did not:** persist the plan as a file. Ours lived only
in the conversation, so it did not survive compaction and could not be handed to a
fresh executor as an artifact. Since the Codex finding forced *both* lanes to use
fresh executors, persistence stopped being optional.
