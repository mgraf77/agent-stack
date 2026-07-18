---
name: change-impact
description: Use before requesting review, opening a PR, or deciding how carefully to review a diff — bucket the changed files by risk category (security-sensitive, schema/migration, config/infra, generated/vendored, tests-only, docs-only, code) and read the suggested review depth per bucket instead of reviewing every file with the same amount of attention.
license: MIT
---

# Change Impact

Not every changed file deserves the same review depth. Triage first, then
spend attention where the risk actually is.

## Process

1. Get the changed-file list: `git diff --name-only <base>...` (or any
   other source of paths — a PR's file list works too).
2. Run `classify-diff.sh` over that list (via a file argument, or piped on
   stdin) to get a sorted table of `path -> category` plus a suggested
   review depth per category present in the diff.
3. Spend review effort accordingly: full read-through for
   `security-sensitive`/`schema-or-migration`, a careful pass for
   `config-or-infra`, a confirm-not-hand-edited check for
   `generated-or-vendored`, and a lighter pass for `tests-only`/
   `docs-only`.
4. If a change touches UI/frontend behavior, also run `browser-qa` — this
   skill only classifies risk by path, it does not replace driving the app.

## A heuristic, not a verdict

The categorizer is pattern-based on file paths, not the actual diff
content — treat its output as a starting triage, not a substitute for
reading a `security-sensitive` or `schema-or-migration` file's actual
change. A path can be miscategorized (a helper under `tests/` that also
changes production config, for instance); when in doubt, read the file.

## Untrusted content handling

The changed-file list can come from an untrusted branch or an external
contributor's PR — a path could be deliberately named to be
miscategorized (e.g. hiding a config change inside a path that looks
docs-only). `classify-diff.sh` only pattern-matches path strings with
fixed rules; it never reads file contents, sources, or executes anything
from the diff, and its output is a hint for where to look closer, not an
authority to skip review of anything it buckets as low-risk.

## Usage check

`check.sh` runs `classify-diff.sh` against a bundled fixture list covering
all seven categories and confirms each path lands in the expected bucket.
