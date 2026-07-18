# Promotion lifecycle

Every catalogued source (`catalog/repositories.csv`) carries one decision.
Capability records (`catalog/capabilities/*.json`) may only exist for
sources whose decision allows reuse, and their `status` must stay
consistent with that decision:

| Catalogue decision | Capability status | Meaning |
| --- | --- | --- |
| `ADOPT NOW` | `adopt_now` | Ready for use in a project profile now. |
| `PILOT` | `pilot` | Trial only, normally via the `experimental` profile, on a bounded task before wider use. |
| `HARVEST` | `harvest` | Reuse the ideas/patterns; do not run the upstream project as-is. |
| `WATCH` | `watch` | Track; not yet compatible or not yet needed. Rarely warrants a capability record until it moves to a stronger decision. |
| `DO NOT USE` | — | No capability record. |
| `UNRESOLVED` | — | No capability record until identity/license is resolved. |

## Capability records are not exportable skills

A capability record only tracks catalogue provenance. It has no runtime
effect on its own: `scripts/sync.mjs` never reads `catalog/capabilities/`.
For a capability to actually run as part of an agent's loaded
instructions, it needs its own `skills/<id>/SKILL.md` and an entry in the
relevant profile(s)' `skills` array.

## Adding a capability record's catalogue reference to a project profile

1. Confirm the capability record's `status` and the catalogue row's
   `decision` still agree.
2. Add the project's `profile` value to the capability's
   `compatible_profiles` array.
3. Add the capability's `id` to the project's `profiles/<profile>.json`
   `capabilities` array.
4. Run `python3 scripts/validate.py`.

## Promoting a curated skill into a project profile

1. Confirm `skills/<id>/SKILL.md` exists and is compatible with the
   project.
2. Add `<id>` to the project's `profiles/<profile>.json` `skills` array
   (kebab-case, no duplicates, no arbitrary cap).
3. Run `python3 scripts/validate.py`.
4. Record a sync receipt (`schemas/sync-release-receipt.schema.json`,
   written by `scripts/sync.mjs --mode apply`) when the profile is
   actually delivered to a product repository.

## Promoting a real curated skill through the local evaluation gate

A real `skills/<id>/` package can go through the same trial → approved gate
as a synthetic capability (see "Local evaluation gates" below), using its
own files instead of a separate fixture-shaped candidate directory:

1. Add `skills/<id>/promotion.json`, matching
   `schemas/skill-promotion-manifest.schema.json`: provenance
   (`agent-stack-local`, or the catalogued upstream source it was adapted
   from), `declared_tools`, `trigger_keywords`/`positive_examples`/
   `negative_examples`, `untrusted_content_handling`, and a `rollback`
   object (method + date recorded) — the same information
   `rollback.receipt.json` records for a synthetic candidate, carried in
   one file instead of two.
2. Point `entrypoint` at the skill's own existing safe-usage check (e.g.
   `check.sh`) where the skill already has one runnable — do not add a new
   `run.sh`, and do not require a runtime executable at all when the skill
   is instruction-only: set `instruction_only: true` and omit `entrypoint`
   instead. `failure_behavior`/`permission_boundary` are then not
   applicable rather than failed for missing a script.
3. Confirm `SKILL.md` states explicit untrusted-content handling guidance
   when `untrusted_content_handling: true`, as the `prompt_injection` check
   requires the same as it does for a synthetic candidate.
4. Run `bash evals/run.sh --skill skills/<id>`. All six checks must PASS
   before the skill moves beyond `pilot`/`experimental`, exactly as for a
   `--capability` candidate.
5. Record the transition with
   `evals/templates/promotion-record-template.md`, same as any other
   candidate.

`secret-safety` is migrated this way as the first real skill on this route
(`skills/secret-safety/promotion.json`); see `evals/README.md` for the
`--skill` usage and the negative-control fixture proving the gate actually
discriminates. No other curated skill is migrated by this change — see
`evals/fixtures/skills/README.md` before adding more.

## No auto-merge or autonomous production authority

Promotion is always a reviewable, reversible pull request. This lifecycle
never triggers an automatic merge or an automatic change to a product
repository.

## Local evaluation gates (candidate → trial → approved)

This section adds a free, local, automated gate on top of the steps
above, using `evals/run.sh` (see `evals/README.md`). It supplements the
catalogue-decision/capability-status table; it does not replace it, and
it does not change what `PILOT`/`pilot` already means.

Stage names map onto the existing model like this:

- **Candidate** — a drafted capability with `capability.json`, `SKILL.md`,
  a `run.sh` entrypoint, and `rollback.receipt.json`, not yet added to any
  profile. No eval run is required to remain a candidate.
- **Trial** — the capability's catalogue decision is `PILOT` (status
  `pilot`) and it is listed only in the `experimental` profile, exactly as
  the table above already describes. **Entering trial never requires
  passing every gate below** — that is the entire point of a trial lane.
  A `PILOT`-decision source, or a `pilot`-status capability, must not be
  blocked from the `experimental` profile merely because it hasn't yet
  passed all six checks. Only actual skills/capabilities that fail their
  own defined promotion conditions are held back — a catalogue decision
  of `PILOT` by itself is never a reason to block anything.
- **Approved** — the capability's status moves from `pilot` to
  `adopt_now` (matching an `ADOPT NOW` catalogue decision), and/or it is
  added to any profile beyond `experimental`. This transition requires
  `bash evals/run.sh --capability <path-to-capability-dir>` (or, for a real
  curated skill, `bash evals/run.sh --skill skills/<id>` — see "Promoting a
  real curated skill through the local evaluation gate" above) to pass all
  six checks below, plus a promotion record opened from
  `evals/templates/promotion-record-template.md`.

### The six required checks

All six run locally and for free (`bash`, `jq`, coreutils `timeout` —
nothing else). No provider API key or network call is required, or
permitted, for any of them:

| Check | What it proves |
| --- | --- |
| `positive_activation` | The capability activates on the requests it should. |
| `negative_activation` | The capability does not activate on unrelated requests (catches over-broad triggers). |
| `failure_behavior` | The capability's entrypoint completes within a bounded timeout, and any failure leaves a clear diagnostic; an unbounded hang is an unsafe failure. |
| `permission_boundary` | The capability only uses the tools it declared. |
| `prompt_injection` | The capability documents untrusted-content handling, and the eval harness itself never executes fixture/external content. |
| `rollback_evidence` | A complete `rollback.receipt.json` exists, recording how to undo the capability (or, for a real skill gated with `--skill`, an equally complete `rollback` object in its `promotion.json`). |

### Demotion and rollback

Any regression in a required check — a later eval run, a reported
incident, or a source update — demotes the capability back to `pilot`
status and out of any profile beyond `experimental` immediately. The
`rollback_method` recorded in the capability's `rollback.receipt.json` is
then the executed plan.

### Provider-backed checks

None exist, and none should be added. Every required check above is free
and local per `policies/free-first.md`; a paid-provider-backed variant
does not belong in this repository even as an optional, disabled-by-
default example.
