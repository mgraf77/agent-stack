# Pilot Tasks — Worked Example

A filled-in example of `docs/pilot.md`, using a generic product repo
called `example-product`. Replace with your own real tasks; nothing here
is a real issue.

## Task 1 — One bug

**Issue:** "Signup form accepts an empty email field and creates a user
with no email, breaking the welcome-email job. Steps to reproduce: submit
the signup form with the email field blank. Expected: form rejects the
submission client- and server-side. Fixed when: an empty email cannot
reach the create-user path, with a regression test."

**Flow:** `templates/prompts/start-task.md` with Claude Code → PR opened →
`templates/prompts/request-review.md` with Codex → Codex flags that the
server-side check was added but the client-side one wasn't → Claude Code
pushes a follow-up commit → merge.

## Task 2 — One medium feature

**Issue:** "Add CSV export to the orders list page. Scope: a button on the
existing orders list that downloads the currently filtered/sorted rows as
CSV, reusing existing filter/sort state. Out of scope: scheduled exports,
email delivery, new filter types. Done when: exported CSV matches what's
on screen for at least three different filter combinations, covered by a
test."

**Flow:** same start-task → review → merge loop. Because scope is
explicit, review focuses on whether the implementation stayed inside it
(no email delivery accidentally added) rather than re-litigating scope.

## Task 3 — One PR remediation

**Setup:** the Task 2 PR came back from Codex's review with two comments —
one real edge case (empty result set exports a header-only CSV, which is
fine, but the button was disabled when it shouldn't be) and one
CI failure (a lint rule on unused imports).

**Flow:** `templates/prompts/resume-session.md` pointed at the Task 2
branch and PR → Claude Code reads the review comments and CI log, fixes
both, pushes → Codex re-reviews the diff only (not the whole PR again) →
merge.

## What a pilot write-up might say

- The client/server validation gap in Task 1 wouldn't have been caught
  without an independent reviewer — confirms the two-tool review step is
  worth keeping.
- Scope stayed bounded in Task 2 without intervention — no evidence yet
  that a dashboard or task board would have helped.
- Resume prompt correctly avoided redoing Task 2's work in Task 3.
