# Patches

This directory is for the rare case where a small, compatible, licensed
slice is reused closely enough that it warrants its own file, separate from
an independent adaptation recorded in `notices/`.

Policy: default to independent adaptation (write concise, original
instructions inspired by an upstream skill's *role*, not its text). Only
place something here when a structural convention (not narrative prose) is
reused nearly as-is. Each patch file must itself carry source URL,
version/commit, license, and exactly what was kept vs. changed — the same
requirement `notices/` applies to everything else.

## Current patches

- [plan-spec-cavekit-section-scheme.md](plan-spec-cavekit-section-scheme.md)
  — the Goal/Constraints/Interfaces/Invariants/Tasks section scheme used by
  `skills/plan-spec/templates/SPEC.template.md`, reduced from Cavekit's
  seven-section `FORMAT.md` scheme.
