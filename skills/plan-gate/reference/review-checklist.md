# Review checklist

Run by the orchestrator, on the frontier model, before releasing execution.
The gate has value only if rejecting is real. Approving everything means you paid
the plan cost and bought nothing.

## Reject outright

Any one of these. Do not negotiate, send it back.

- **`restated_goal` is not the task.** The whole point of the gate. Everything
  after it is wasted effort.
- **`changes` is prose, or has no paths.** Not a plan, an intention.
- **Files appear that the task never implied.** Scope creep at plan time becomes
  scope explosion at execution time.
- **`open_questions` is empty on genuinely ambiguous work.** The model resolved
  ambiguity silently, which is the drift you were gating against.
- **`wrongness` is generic.** "May need testing" is not a falsifier. It means the
  model did not examine its own assumptions.
- **A `changes` row has a live `depends on` and you are about to approve it.**
  That row is not yet a contract. Answer the question first or cut the row.
- **`approach` names a rejected alternative that reads as manufactured.** Two
  independent planners produced strawmen here when the field demanded one. Treat a
  hollow alternative as a signal the planner was performing, and discount the
  confidence of the rest of the plan accordingly.
- **`verification` is self-assessment.** "Confirm it works" is not a check. It has
  to be a command with an expected result.
- **Edits were made during the plan pass.** The gate failed. Revert and find out
  why the tool restriction did not hold.

## Answer before approving

Every entry in `open_questions`. This is the orchestrator's actual job in the
loop: it is the expensive model supplying the judgment the cheap one cannot.

Answering is not rubber-stamping the planner's recommendation. In the 2026-09-05
A/B, an unguided executor made a **better** call than the planner's stated
recommendation on one of four questions. The planner's pick is an input, not a
default.

Where you disagree with the planner's recommended option, say why. The reason
travels with the approval and constrains the execution.

## Check across parallel plans

When several agents planned against overlapping surfaces, before releasing any:

- Does the same file appear in two `changes` tables? Sequence them or merge.
- Do two plans assume incompatible things about shared state?
- Is one plan's `out_of_scope` another's core change? That is a real disagreement
  about the task, not a scheduling problem. Resolve it before either runs.

## Approving

State the approval explicitly, with the answers folded in, and name what is
**not** authorized:

> Approved. Answers: (1) rotate on every refresh, (2) keep the existing table.
> Execute exactly the `changes` table. Do not touch the migration files.

Vague approval is how an approved plan becomes an unapproved change.

## After execution

Review the diff against the `changes` table, not against your memory of the plan.
Anything in the diff and not in the table is drift, however reasonable it looks.

## What this checklist cannot do

**The orchestrator is a model approving a model.** That is one level of remove, not
independent oversight. `optim-plans` draws the line explicitly: its handoff
question states that auto-complete "cannot approve this native handoff, only human
choice is permitted."

We do not enforce that, and pretending otherwise would be the same failure this
skill exists to prevent. So: on anything hard to unwind, a **human** approves the
plan, not the orchestrator. Reserve model-only approval for reversible work in a
clean tree.

## Grade your own findings

Borrowed from `plan-critique-skills`: mark each review finding `CONFIRMED` (you
checked it against the code or a command) or `UNVERIFIED` (it reads wrong but you
did not confirm it). An ungraded review pushes the reviewer's uncertainty onto the
executor silently, which is the same defect as an unmarked `INFERRED` in a plan.
