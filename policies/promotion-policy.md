# Promotion policy: candidate → trial → approved

This policy defines when a capability (a skill, adapter, or profile entry
sourced via `catalog/repositories.csv`) may move between stages. It reuses
the catalogue's existing decision column as input and never rewrites it —
a `catalog_decision` of `ADOPT NOW`, `PILOT`, `HARVEST`, or `WATCH` is a
starting signal, not a substitute for passing the gate below.

All required checks run locally, for free, using `evals/run.sh`. No stage
in this policy requires a paid provider call.

## Stages

### Candidate

A capability is a candidate as soon as it has:

- a source-of-truth entry in `catalog/repositories.csv`,
- a drafted `capability.json` and `SKILL.md` describing what it does, its
  trigger conditions, and its declared tools,
- a `rollback.receipt.json` recording how to undo it.

No eval run is required to remain a candidate. A candidate is not enabled
in any profile.

### Trial

A capability may enter trial once:

- `bash evals/run.sh --capability <path>` passes all six checks
  (`positive_activation`, `negative_activation`, `failure_behavior`,
  `permission_boundary`, `prompt_injection`, `rollback_evidence`),
- a promotion record has been opened from
  `evals/templates/promotion-record-template.md` with the candidate → trial
  transition filled in,
- it runs on at most one bounded, low-risk, reversible task with a named
  owner watching for regressions.

### Approved

A capability may move from trial to approved once:

- it has passed the same eval run again with no regressions since the
  trial began,
- the promotion record's trial-evidence section is filled in with the
  bounded task(s) actually run and any incidents observed,
- the record is committed with an approver and date.

Only approved capabilities may be included in a profile.

## Demotion and rollback

Any regression in a required check — found on a later eval run, a reported
incident, or a source update — demotes the capability back to trial or
candidate immediately. The rollback method recorded in
`rollback.receipt.json` is then the executed plan: remove the capability
from any profile, revert the commit that added it, and record the
demotion in its promotion record.

## Provider-backed checks

Examples under `evals/optional/` may supplement human judgment (e.g. a
semantic read on whether a model would naturally pick a capability) but
are never required at any stage. They are disabled by default and must be
opted into explicitly by a human running them manually.

## Non-goals

This policy does not create a second backlog or task system. Promotion
records live alongside the capability's fixtures/definition and are
reviewed the same way as any other pull request.
