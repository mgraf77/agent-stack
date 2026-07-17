# Notices

This directory records provenance for every upstream-inspired asset under
`skills/`, per `AGENTS.md`'s source-reuse rule: canonical URL, version/commit
observed, license, and local modifications for each imported asset.

## Policy applied in this batch

- All seven upstream sources evaluated below are MIT-licensed per
  `catalog/repositories.csv`.
- No file was copied verbatim from any upstream repository. Every
  `skills/*/SKILL.md` and its supporting scripts/templates/fixtures are
  independently written, inspired by the named upstream skill/command's
  *concept* (its role and shape), not its text or code.
- The one exception — a short, structural, non-prose convention reused
  nearly as-is (a section-header scheme, not narrative text) — is called out
  explicitly in `patches/` with its own notice below.
- `promptfoo/promptfoo` and `kepano/obsidian-skills` were reviewed as
  required sources for this curation pass. Neither maps directly onto one of
  the seven starter skills; promptfoo's declarative-assertion pattern
  informed the general shape of `evidence-before-done`'s usage check
  (fixture-in, expected-result-out), noted below. Both remain good
  candidates for future skills (an eval/assertion skill from promptfoo, a
  vault-markdown skill from obsidian-skills) once the profile layer asks
  for them.

## Sources evaluated (all MIT)

| Source | URL | Version/commit observed | License |
|---|---|---|---|
| gstack | https://github.com/garrytan/gstack | main, ~360 commits, observed 2026-07-17 | MIT |
| Everything Claude Code (ECC) | https://github.com/affaan-m/ECC | v2.0.0, observed 2026-07-17 | MIT |
| Superpowers | https://github.com/obra/superpowers | v6.1.1, observed 2026-07-17 | MIT |
| Cavekit | https://github.com/JuliusBrussee/cavekit | v4 (main), previously frozen v3.1.0, observed 2026-07-17 | MIT |
| OpenSpec | https://github.com/Fission-AI/OpenSpec | v1.6.0, observed 2026-07-17 | MIT |
| Promptfoo | https://github.com/promptfoo/promptfoo | v0.121.19, observed 2026-07-17 | MIT |
| Obsidian Skills | https://github.com/kepano/obsidian-skills | main, ~46 commits, observed 2026-07-17 | MIT |

Per-skill notices:

- [orientation.md](orientation.md)
- [plan-spec.md](plan-spec.md)
- [evidence-before-done.md](evidence-before-done.md)
- [pr-feedback.md](pr-feedback.md)
- [secret-safety.md](secret-safety.md)
- [browser-qa.md](browser-qa.md)
- [handoff.md](handoff.md)
