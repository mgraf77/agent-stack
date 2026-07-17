---
name: evidence-before-done
description: Use before declaring any task, fix, or PR complete. Require a concrete piece of evidence (command output, test run, screenshot, log line) for every claim of "done" or "fixed" rather than asserting it worked. Applies to code changes, config changes, and answers that depend on checking something.
license: MIT
---

# Evidence Before Done

An assertion that something "should work now" is not evidence that it does.
Before closing out a task, attach the concrete thing that proves the claim.

## Rule

For every claim in a completion summary, there must be a matching piece of
evidence:

| Claim | Evidence |
|---|---|
| "Fixed the bug" | Reproduced the failure, applied the fix, reran the same repro, show the before/after output |
| "Tests pass" | Actual test run output, not "should pass" |
| "The UI works" | Exercised in a real browser (see `browser-qa`), not just type-checked |
| "No regressions" | Ran the relevant existing suite, not just the new test |
| "Config is valid" | Ran the tool that parses/validates it |

If you cannot produce the evidence — no browser available, no test suite,
no way to run the affected system — say that explicitly. "I could not verify
X because Y" is honest and useful. A confident claim with no evidence is not.

## Banned phrasing without evidence attached

Treat these as a signal to stop and go get evidence, not to finish the
sentence: "should work", "this fixes it", "that should do it", "now it
works" — unless immediately followed by the actual output that shows it.

## Process

1. Identify what changed and what behavior it's supposed to affect.
2. Exercise that behavior directly — run the command, hit the endpoint,
   click through the UI, run the test.
3. Capture the output (paste it, or note the file/line it came from).
4. Only then state the claim, with the evidence attached or referenced.

## Usage check

`check.sh` scans a text file (e.g. a draft PR description or completion
summary) for banned unverified-claim phrasing that isn't paired with an
evidence marker (`Ran:`, `Output:`, `Verified:`), and flags each hit with its
line number.
