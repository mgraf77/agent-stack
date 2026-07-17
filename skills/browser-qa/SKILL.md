---
name: browser-qa
description: Use when a change touches UI or frontend behavior. Drive the actual app in a real browser through the golden path plus one or two edge cases before claiming the feature works — type-checking and unit tests verify code correctness, not that the feature behaves correctly for a user.
license: MIT
---

# Browser QA

A change "passing tests" and a change "working in the browser" are different
claims. For any UI-affecting change, verify the second one directly.

## Process

1. **Start the app** the normal way for this project (dev server, local
   build, etc.).
2. **Open a real browser** against it — Chromium via Playwright is a good
   default when available locally; a manual browser works too.
3. **Exercise the golden path**: the primary flow the change is meant to
   affect, from a user's first interaction through to the expected result.
4. **Exercise 1–2 edge cases**: empty state, invalid input, a second time
   through the flow, an adjacent feature that shares the changed code path.
5. **Check for regressions nearby**: features that share a component or
   state with what changed.
6. **Watch the console** for errors/warnings the visual check alone would
   miss.
7. **Capture evidence** (screenshot, console output) — see
   `evidence-before-done`; "I clicked through it" is stronger when there's a
   screenshot or trace attached.

## If you can't verify

State plainly that you could not exercise the UI directly (no browser, no
running app, headless environment without a display) rather than inferring
success from the diff or from tests alone.

## Usage check

`templates/smoke.spec.template.js` is a minimal Playwright script skeleton
(constants at the top for base URL and selector — no live app assumed).
`check.sh` runs `node --check` against it to confirm it's syntactically valid
JavaScript before you copy it into a real project and fill in the constants.
