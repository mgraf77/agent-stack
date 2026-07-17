---
name: handoff
description: Use at the end of a work session, task, or before switching away from a branch. Write a short structured handoff — changed paths, why, validation performed, remaining risks — so the next session (yourself or someone else) can resume without re-deriving context from scratch.
license: MIT
---

# Handoff

A handoff is a summary for resuming work, not a report to impress anyone.
Keep it short and structured; a long narrative is harder to resume from than
a tight list.

## Required fields (`templates/HANDOFF.template.md`)

- **Changed** — the paths actually touched, not a restatement of the whole
  task.
- **Why** — one line of intent, enough to tell an unrelated change from an
  intentional one.
- **Source material** — anything copied/adapted from elsewhere, with
  attribution (see `notices/` convention if this is a curation task).
- **Validation** — what was actually run/checked, referencing
  `evidence-before-done` rather than restating unverified claims.
- **Remaining risks / follow-ups** — what's known-incomplete, deferred, or
  could break; do not bury this in prose where it will be missed.
- **Current state** — branch/PR link and whether it's ready for review,
  blocked, or still in progress.

## When to write one

- End of a session on a nontrivial task.
- Before handing a PR to a reviewer or to another agent/session.
- Before switching away from a branch with uncommitted or unmerged work.

Skip it for a single trivial edit with nothing left to track.

## Usage check

`check.sh` validates that a filled-in handoff file has all required section
headers present, so it's usable as a resumption point rather than free-form
prose that omits the parts someone needs.
