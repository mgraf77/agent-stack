# Agent Stack Changelog

Human-readable release notes. Newest first. Each entry should let a
project owner decide whether to refresh their pin without reading the
diff. See `release/CHECKLIST.md` for how entries get added and how to
deprecate a bad release.

## Unreleased

- Added operator onboarding docs (`docs/`), copy-paste prompt templates
  (`templates/`), release/rollback checklist (`release/`), and worked
  examples (`examples/`). No skills, profiles, or catalog entries changed.
- Updated onboarding docs, templates, and examples to describe the real
  `scripts/sync.mjs` / `scripts/doctor.mjs` pin and drift-check commands
  and the actual `sync-receipt.json` format, replacing the earlier
  hand-copy-and-invent-a-receipt placeholder description. No changes to
  `adapters/`, `profiles/`, or the sync implementation itself.
