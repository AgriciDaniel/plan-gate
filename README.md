# Plan Gate

<p align="center">
  <img src="assets/cover-plan-gate.jpg" alt="Plan Gate cover" width="100%">
</p>

**A plan-first gate for AI coding agents. It makes a cheap model show you its plan before it is allowed to touch anything.**

Here is the skill, here is what it does, here is how to install it.

## What it does

You delegate work to a cheaper model. It explores the code read-only, hands back a plan and every question it needs answered, and only gets write access after you approve. If it never gets approval, it never writes. That part is not a promise in a prompt, it is enforced.

Two ways to run it:

- **Lane A**, a subagent restricted to read-only tools.
- **Lane B**, Codex running inside a read-only OS sandbox.

## Which agents

The method is agent-agnostic. The enforcement is not, because every runtime restricts capability differently.

| | Status |
|---|---|
| **Claude Code** | Enforced and tested. Read-only `tools:` allowlist |
| **Codex / GPT** | Enforced and tested. Read-only OS sandbox |
| **Cursor, Gemini CLI, Copilot, others** | Method and documents port directly. You supply the capability restriction |

The plan schema and the review checklist are plain Markdown and carry no vendor assumptions, so they work anywhere. `SKILL.md` follows the Agent Skills format. What does not port is the enforcement primitive: `agents/plan-gate-planner.md` and `audit.sh` read Claude Code's agent format specifically.

The important part transfers even when the wiring does not: **restrict the capability, do not ask the model nicely.** A prompt telling a model not to write is not a gate, in any runtime.

## Install

```bash
git clone https://github.com/AgriciDaniel/plan-gate.git
cd plan-gate
./install.sh
```

Restart Claude Code. Agent files load at session start.

For other agents, copy `skills/plan-gate/` where your runtime reads skills, and replace the Lane A planner with whatever read-only restriction that runtime offers.

```bash
./install.sh --dry-run   # preview first, backs up anything it would replace
```

## Use it

Three levels. Start with the cheapest.

**1. No gate.** Most of the time. Specified work, one file, lookups.

**2. One line.** The everyday default. Add this to any delegation:

> Report anything you decided that the task did not specify.

**3. The full gate.** Only when the work is genuinely uncertain:

```
/plan-gate <task>       plan, review, execute, verify
/plan-gate claude       Lane A, read-only planner subagent
/plan-gate codex        Lane B, read-only pass then a fresh write pass
/plan-gate preflight    is Lane B safe on this machine
/plan-gate audit        can the planner still not write
```

Gate when the change touches more than 3 files, when you are root-causing rather than localizing, when requirements are still fuzzy, or when two agents are working the same files.

## What testing showed

I built this, then tested it properly. Two results argue against using it, and they are in the README because they are the most useful thing here.

**What worked:** the gate holds. In a controlled A/B, the read-only agent's copy of the files came back byte-for-byte untouched. It could not write, in a session mode where the permission setting is ignored.

**What failed:** on a well-specified task, the gate bought nothing. The ungated agent matched the plan and answered one of four open questions *better* than the planner had recommended.

| | tokens | tools | time | result |
|---|---|---|---|---|
| Ungated | 76k | 14 | 162s | Correct, clean, no scope creep |
| Gated, plan only | 26k | 8 | 119s | Plan and 4 questions, wrote nothing |

**What also failed:** my own design. I claimed Codex could pause, get approval, then resume with write access and keep its context. It cannot. Confirmed by a live run and by [openai/codex#33974](https://github.com/openai/codex/issues/33974). Both passes have to be fresh, so the plan carries the context.

So the honest default is **do not gate**. Use level 2 most days. Full evidence in [`evidence/`](evidence/).

## What is in here

| | |
|---|---|
| `skills/plan-gate/` | the skill, its reference docs, two scripts |
| `agents/` | the read-only planner |
| `evidence/` | the A/B test, the Codex finding, the prior-art survey |
| `HANDOFF.md` | how to use it, what is still open |
| `install.sh` | idempotent, backs up, `--dry-run` |

## Known limits

- **The reviewer is a model.** The orchestrator approving a plan is a model approving a model. On anything hard to unwind, a human should approve.
- **Tested once per arm.** Single runs mislead in both directions.
- **Only two runtimes are wired up.** Claude Code and Codex are enforced and tested. Everything else needs its own restriction primitive.
- **Codex needs a real sandbox.** Its sandbox cannot run inside the VS Code Flatpak. It fails and returns empty results while exiting 0, which reads like a valid empty plan. Run `/plan-gate preflight` first and treat an empty plan as a failure.

## License

MIT.
