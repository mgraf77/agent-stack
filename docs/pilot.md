# First Pilot: Three Tasks

Before adding any process beyond what's in `docs/onboarding.md`, run these
three tasks against one real (or realistic) product repo, in order. Each
uses the plain prompts in `templates/prompts/`. A worked, filled-in example
of all three is in `examples/pilot-tasks.md`.

## Task 1 — One bug

Pick a small, real, reproducible bug. Bounded to one PR.

1. File the issue: what's broken, how to reproduce it, what "fixed" means.
2. Run `templates/prompts/start-task.md` with Claude Code.
3. Run `templates/prompts/request-review.md` with Codex against the
   resulting PR.
4. You merge (or send it back) on GitHub.

**Success:** PR merged, bug no longer reproduces, no unrelated files
touched.

## Task 2 — One medium feature

Pick a feature that touches more than one file but still fits one PR — not
a rewrite, not a new subsystem.

1. File the issue with explicit scope boundaries (owned paths, what NOT to
   touch — copy the pattern from this repo's own issue #5 if useful).
2. Same start-task → review → merge loop as Task 1.

**Success:** PR merged, feature works as described, scope boundaries were
respected without you having to intervene mid-task.

## Task 3 — One PR remediation

Take a PR that has real review feedback or a failing check (can be the
Task 1 or Task 2 PR if either drew comments, or any other open PR).

1. If the session that opened the PR is still around, resume it with
   `templates/prompts/resume-session.md`. If not, start fresh but point
   directly at the PR and its comments/CI output.
2. Have the tool address the feedback and push updates to the same branch.
3. Re-review with the other tool if the changes are non-trivial.

**Success:** PR reaches a mergeable, green state without you re-explaining
the original task from scratch.

## After the pilot

Write down, honestly:
- Where you had to intervene that the flow should have handled itself.
- Where a skill was missing or a profile didn't fit.
- Whether anything in `docs/onboarding.md` §5 (no-overengineering) actually
  needs revisiting now, with a concrete reason — not preemptively.

That write-up is the input to the next round of work, not this doc.
