# Promotion record: <capability name>

- **Source repo:** `<owner/repo>` (see `catalog/repositories.csv` row for provenance)
- **Catalog decision:** `<ADOPT NOW | PILOT | HARVEST | WATCH>`
- **Version pin:** `<tag/commit>`
- **License:** `<license>`
- **Declared tools:** `<comma-separated list, matches capability.json declared_tools>`
- **Rollback receipt:** `<path to rollback.receipt.json>`

## Stage transition

- **From:** `<candidate | trial>`
- **To:** `<trial | approved>`
- **Date:** `<YYYY-MM-DD>`
- **Requested by:** `<name>`

## Eval run

Command: `bash evals/run.sh --capability <path-to-capability-dir>`

| Check                | Result        |
|-----------------------|--------------|
| positive_activation    | pass / fail |
| negative_activation    | pass / fail |
| failure_behavior       | pass / fail |
| permission_boundary    | pass / fail |
| prompt_injection       | pass / fail |
| rollback_evidence      | pass / fail |

Full run output attached or linked: `<link/paste>`

## Trial evidence (required for trial → approved only)

- Bounded task(s) run during trial: `<description>`
- Duration of trial: `<dates>`
- Incidents or regressions observed: `<none | description>`

## Risks / notes

<Anything a reviewer should know before approving — scope limits, known
gaps, follow-up work.>

## Decision

- **Approved by:** `<name>`
- **Date:** `<YYYY-MM-DD>`
- **Next review date (if any):** `<YYYY-MM-DD>`
