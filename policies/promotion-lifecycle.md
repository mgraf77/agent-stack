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

## No auto-merge or autonomous production authority

Promotion is always a reviewable, reversible pull request. This lifecycle
never triggers an automatic merge or an automatic change to a product
repository.
