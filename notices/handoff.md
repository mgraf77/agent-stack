# Notice: skills/handoff

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| Everything Claude Code (ECC) | https://github.com/affaan-m/ECC | v2.0.0, observed 2026-07-17 | MIT |

## What was used

The general concept behind ECC's `status.md` generation (`ecc status
--markdown`, described as a "portable handoff covering readiness, active
sessions, skill-run health") and `checkpoint.md` command (save verification
state): a short, structured, resumable status artifact rather than prose.
No ECC file, generated output format, or text was copied.

## Local modifications

The required-field list (Changed, Why, Source material, Validation,
Remaining risks/follow-ups, Current state) reflects this repository's own
`AGENTS.md` change-discipline rule ("include a concise handoff with changed
paths, source material, validation, and remaining risks") more directly than
ECC's fields, and was written independently. `templates/HANDOFF.template.md`
and its `check.sh` section-header validator are original to this
repository.
