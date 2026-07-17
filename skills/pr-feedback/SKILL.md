---
name: pr-feedback
description: Use when responding to PR review comments, requested changes, or CI failures. Triage each item by category, act on the clear ones, ask before the ambiguous or architecturally significant ones, and keep iterating on CI failures until the terminal state (green or a real blocker) instead of stopping after one attempt.
license: MIT
---

# PR Feedback

Reviewers and CI produce a queue of items. The job is to clear it
methodically, not to react to the newest comment in isolation.

## Triage each item into one category

| Category | Action |
|---|---|
| Typo / nit / clearly correct suggestion | Fix it, push, no reply needed unless it resolves a thread |
| Clear bug the reviewer found | Fix it, verify (see `evidence-before-done`), push, reply only if it resolves the thread or raises a follow-up question |
| Ambiguous or could be read multiple ways | Ask a clarifying question before changing code — do not guess at intent on anything architecturally significant |
| Out of scope for this PR | Say so, and note it as a follow-up rather than silently dropping it or silently expanding the PR |
| CI failure | Diagnose the actual cause; do not re-run blindly hoping it passes |

## CI failures specifically

A single fix-and-rerun is not the task if the ask was "get this green" or
"make it mergeable" — that has a terminal state you drive to. On each new
failure: re-diagnose (don't assume it's the same cause as last time), fix,
push, and check again. Stop and report when either it's green, or you've
made several attempts with no progress and need input.

## Don't go silent

- If nothing is actionable in a batch of feedback, it's fine to make no
  change — but say that, don't just do nothing with no acknowledgment.
- If a review comment could be interpreted more than one way, or touches
  something structurally significant, ask before acting rather than guessing
  and pushing a wrong fix.
- Keep a running status (see `templates/triage.template.md`) so the thread
  shows live state instead of requiring someone to re-read every comment.

## Usage check

`check.sh` validates that a filled-in triage file has the required columns
(comment, category, action, status) so the table stays usable as a live
status board rather than free-form prose.
