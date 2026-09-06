# Plan schema

The plan is the **context transfer**: on Lane A a fresh executor sees this and
nothing else, so anything omitted gets rediscovered at full cost or guessed at.

Return all ten fields, in this order, as markdown, using `## 1. restated_goal`
style headings. Keep the numbering and the snake_case names so the review
checklist can be applied mechanically across different planners.

## 1. `restated_goal`

The task in your own words. One line is fine and one line is often correct. If
this does not match what the orchestrator meant, nothing else matters. Do not pad
it on a task that was already precisely stated.

## 2. `done_when`

The completion criteria, frozen. Write this **before** the approach, and do not
revise it later in the plan. If the executor finishes and this is not satisfied,
the work is not done; if it does something outside this, that is scope creep.

Borrowed from `anilcancakir/claude-code`, which hashes its "done" definition
before starting for exactly this reason. Our A/B showed scope expansion is the
characteristic ungated failure, so freezing the target early is cheap insurance.

## 3. `constraints`

Rules you must obey that are **not** discoverable from the code: house style, a
stated preference, a deadline, a library you may not add. Inherited from the
requester, not from the repository.

If you leave this empty, an executor reading only your `changes` table will not
know they exist. Say "none stated" rather than omitting the field.

## 4. `findings`

What you established by reading, each with `path:line`. Mark anything you inferred
but did not confirm as `INFERRED`. Facts only.

## 5. `approach`

The chosen approach in a few sentences.

Name an alternative **only if you genuinely weighed one.** If the problem was
constrained enough that no real alternative existed, write "no real alternative:
<reason>". A manufactured rejected option is worse than none, because a reviewer
cannot distinguish it from real deliberation and it inflates confidence in the
plan. This field is not a place to demonstrate thoroughness.

## 6. `changes`

One row per file, in application order. If order does not matter, say so.

| # | where | path | change | anchor | depends on |
|---|---|---|---|---|---|
| 1 | replace | `src/auth/session.ts` | add refresh-token rotation | `refreshSession()`, line 84 | - |
| 2 | append | `docs/auth.md` | document the new rotation window | end of "Sessions" section | Q1=(a) |

- `where` is `replace`, `insert-before`, `insert-after`, `append`, or `create`.
  An insertion needs a position; a modification needs a symbol. They are not the
  same thing and `anchor` alone conflates them.
- `depends on` names the open question a row is conditional on, or `-`. A row with
  a live dependency is **not yet approved** even if the plan is.
- For content and documentation edits, the change often *is* the exact text. Put
  it in a fenced block directly under the table, labelled with the row number.
  That is expected, not a violation.

## 7. `verification`

The exact command that proves the change worked, and the expected result. It must
be something you cannot fake by asserting success.

Include what to do if it fails: the likely cause and how to back out. A plan that
tells the executor how to detect failure and then abandons them is half a plan.

## 8. `out_of_scope`

What you are deliberately not touching. This is the anti-drift field. An executor
tempted by something nearby checks here first.

## 9. `open_questions`

Every question, in one batch. You get one handoff, not a conversation.

Each as: the question, the options, and which you would pick and why. Cross-
reference the `changes` rows that depend on it. Empty is valid only when the task
was genuinely fully specified.

## 10. `wrongness`

What would make this plan wrong, and the concrete observation that would prove it.
Not a generic caveat. "May need testing" is not a falsifier.

## Rules

- No edits during the plan pass. Not one file, not a quick fix on the way past.
- Uncertainty is reported, never smoothed. `INFERRED` and `wrongness` exist so you
  do not have to sound more confident than you are.
- If the task is trivial and the gate is wasted ceremony, say so in `approach` and
  keep the plan to three lines. That is a useful result, not a failure.
- If you cannot form a plan, return `findings`, `open_questions` and `wrongness`,
  and stop.

## For the executor

If you receive this plan with any `open_questions` unanswered, **stop and ask.**
Do not pick. A question that reached you unanswered was not reviewed by anyone,
and the row that depends on it is outside the approved contract.
