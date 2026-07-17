# Notice: skills/evidence-before-done

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| Superpowers | https://github.com/obra/superpowers | v6.1.1, observed 2026-07-17 | MIT |
| Promptfoo | https://github.com/promptfoo/promptfoo | v0.121.19, observed 2026-07-17 | MIT |

## What was used

- From Superpowers: the concept behind their
  `skills/verification-before-completion` skill — do not close out a task
  without validating the fix, rather than the skill's actual text. No file
  contents were read verbatim or copied.
- From Promptfoo: the general shape of declarative, assertion-based
  validation (a config declares expected outcomes, a runner checks them)
  loosely informed this skill's `check.sh` pattern — fixture in, expected
  pass/fail out — as a way to make "evidence" a checkable thing rather than
  a claim. No promptfoo config syntax, code, or text was copied.

## Local modifications

The banned-phrase list, the claim/evidence table, and the paragraph-scoped
`check.sh` scanner (implemented with `awk`, no dependencies) are original to
this repository. `fixtures/sample-good.txt` and `fixtures/sample-bad.txt`
are synthetic examples written for this skill's usage check.
