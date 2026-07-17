# Notice: skills/plan-spec

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| OpenSpec | https://github.com/Fission-AI/OpenSpec | v1.6.0, observed 2026-07-17 | MIT |
| Cavekit | https://github.com/JuliusBrussee/cavekit | v4 (main), observed 2026-07-17 | MIT |

## What was used

- From OpenSpec: the general concept of a lightweight, in-repo spec artifact
  (proposal / requirements-with-scenarios / tasks) written before
  implementation, and archived rather than kept as a permanent second
  backlog. No OpenSpec file, command text, or scenario wording was copied.
- From Cavekit: the idea of a compact, fixed section scheme (their
  `FORMAT.md` defines §G/§C/§I/§R/§V/§T/§B — Goal, Constraints, Interfaces,
  Research, Invariants, Tasks, Bugs) and a read-only drift check against
  Invariants/Interfaces/Tasks. This repo's `SPEC.template.md` uses a
  **reduced, independently-worded** version of that section scheme (Goal,
  Constraints, Interfaces, Invariants, Tasks) — see `patches/` for the one
  place this reuses Cavekit's structural convention closely enough to call
  out as a small copied slice rather than a pure adaptation.

## Local modifications

- Dropped Cavekit's §R (Research) and §B (Bugs, backprop-populated) sections
  as out of scope for a lightweight starter template; dropped their symbolic
  §-notation and pipe-table encoding in favor of plain Markdown headings,
  since the token-efficiency optimization that motivates Cavekit's notation
  isn't a goal here.
- All prose (descriptions, "when to write one", drift-check guidance) is
  independently written for this repo, not translated from either source.
