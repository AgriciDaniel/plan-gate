# Prior art survey, 2026-09-06

Searched for anything better or overlapping before extending this skill.

## The claim that mattered most: confirmed

The official subagent docs now state it more strongly than I had it:

> If the parent uses `bypassPermissions` or `acceptEdits`, this takes precedence
> and can't be overridden. If the parent uses auto mode, the subagent inherits
> auto mode and any `permissionMode` in its frontmatter is ignored.

So `permissionMode: plan` fails open under **three** parent modes, not one. The
`tools:` allowlist is even more load-bearing than originally documented.
https://code.claude.com/docs/en/sub-agents

## The Codex finding: confirmed upstream

openai/codex issue #33974, "Allow switching sandbox/approval mode within an active
session":

> The sandbox mode and approval policy have to be decided at process start via CLI
> flags or config. Once a codex session is running, there is no way to switch modes
> without exiting and restarting the process, which loses the entire in-memory
> conversation context.

The proposed `codex session set-sandbox <id>` fix is not implemented. Our
fresh-thread design is correct and unavoidable, not a workaround for my error.
https://github.com/openai/codex/issues/33974

## Comparable projects

| Project | Overlap | Worth stealing |
|---|---|---|
| [anilcancakir/claude-code](https://github.com/anilcancakir/claude-code) | Very high | Frozen "done" criteria, checkpoint commits per wave |
| [Optim-Agent/optim-plans](https://github.com/Optim-Agent/optim-plans) | High | Human-only approval, decisions kept separate from plan |
| [serbanghita/plan-critique-skills](https://github.com/serbanghita/plan-critique-skills) | Medium | CONFIRMED / UNVERIFIED grading on review findings |

**anilcancakir/claude-code** independently reached our central conclusion: it
enforces read-only review by capability, not permission mode. Its `auto-verifier`
"holds no `Edit`, `Write` or `Agent`" tool. It also does per-step tier routing
across haiku/sonnet/opus, which is exactly Daniel's original framing, and runs an
adversarial chain where the plan reviewer reads the plan cold and the code
reviewer sees only the diff.

**optim-plans** makes the sharpest point we were missing: its gate cannot be
approved by the agent. "`Auto-complete` cannot approve this native handoff, only
human choice is permitted." Notably, v0.3.0 removed its execution engine entirely
to focus on planning quality.

**plan-critique-skills** inverts the roles: the human owns the plan and the AI is
the adversarial reviewer.

## Adopted

1. **`done_when`**, frozen completion criteria, now field 2 of the schema. Our A/B
   showed scope creep is the characteristic ungated failure.
2. **Plan persistence** to `plans/<date>-<slug>/plan.md` plus a separate
   `decisions.md`. Since the Codex finding forced both lanes onto fresh executors,
   the plan is the only thing crossing the gate, and a conversation-only plan does
   not survive compaction.
3. **The self-approval limit, stated honestly.** Our orchestrator is a model
   approving a model. The checklist now says so and requires a human approver for
   anything hard to unwind.
4. **CONFIRMED / UNVERIFIED grading** on review findings.

## Not adopted, and why

- **Checkpoint commits per wave.** Good idea, but it presumes a git repo and a
  wave-based executor we do not have. Revisit if this grows an execution engine.
- **A full execution engine.** `optim-plans` removed theirs on purpose. Our A/B
  says the same thing: the gate is worth less than the planning quality.
- **Rewriting to match any of these.** They are bigger and solve a broader
  problem. Ours stays small and covers what happens after `orchestrate` has
  already decided to delegate.
