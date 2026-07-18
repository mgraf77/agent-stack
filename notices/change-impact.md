# Notice: skills/change-impact

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| Cavekit | https://github.com/JuliusBrussee/cavekit | v4 (main), observed 2026-07-17 | MIT |
| Superpowers | https://github.com/obra/superpowers | v6.1.1, observed 2026-07-17 | MIT |

## What was used

- From Cavekit: the general idea of a read-only drift/impact check run
  against a change before calling it done — already reused once for
  `plan-spec`'s "Drift check" section (see `notices/plan-spec.md` and
  `patches/plan-spec-cavekit-section-scheme.md`). Here the same underlying
  idea — check a change against something stated, systematically — is
  applied to risk-categorizing the changed-file list itself rather than
  to a spec's Invariants/Interfaces. No Cavekit file, notation, or text
  was copied.
- From Superpowers: the general concept behind their staged/severity-based
  code-review skills (also referenced once already in
  `notices/pr-feedback.md`) — that not every changed file warrants the
  same review depth, so the process should sort a review queue by risk
  first. No Superpowers file or text was copied.

## Local modifications

The seven risk categories (security-sensitive, schema-or-migration,
config-or-infra, generated-or-vendored, tests-only, docs-only,
code-change), their path-pattern heuristics, and the per-category review
notes are original to this repository. `classify-diff.sh` is an
independent, offline, path-pattern-only implementation — it never reads
file contents or calls a network service. `check.sh` and
`fixtures/sample-changed-files.txt` are original, one path per category.
