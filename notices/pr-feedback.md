# Notice: skills/pr-feedback

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| Superpowers | https://github.com/obra/superpowers | v6.1.1, observed 2026-07-17 | MIT |
| Everything Claude Code (ECC) | https://github.com/affaan-m/ECC | v2.0.0, observed 2026-07-17 | MIT |

## What was used

- From Superpowers: the concept split between their
  `skills/receiving-code-review` (responding to feedback) and
  `skills/requesting-code-review` (severity-based triage, critical issues
  block progress) skills — reusing the idea of categorizing feedback by
  severity/type and gating action on that category. No file text was
  copied.
- From ECC: the general idea behind `ecc work-items sync-github` and
  `status.md` — keeping a live, portable status view of PR/issue queue
  state rather than requiring someone to re-read every comment. No ECC
  file, command output format, or text was copied.

## Local modifications

The triage categories (nit / clear bug / ambiguous / out-of-scope / CI), the
CI "terminal state" framing, and the "don't go silent" section were written
independently for this repository, along with `templates/triage.template.md`
and its `check.sh` column validator.
