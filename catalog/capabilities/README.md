# Capability records

Each file here is one curated, reusable capability derived from a row in
`catalog/repositories.csv`, validated against
`schemas/capability-record.schema.json`.

Capability records are the **source catalogue layer**: they track what
was evaluated, its decision, license, and which profiles it's relevant
to. A capability record is not a substitute for an exportable skill —
`scripts/sync.mjs` never reads `catalog/capabilities/`, it only exports
`skills/<id>/` directories listed in a profile's `skills` array. When a
capability is ready to actually run as part of an agent's loaded
instructions, it needs its own `skills/<id>/SKILL.md` and a `skills`
entry in the relevant profile(s) — the capability record alone does
nothing at sync time.

- Filename must equal the record's `id` plus `.json`.
- `source.canonical_repo_or_product` must match a row in
  `catalog/repositories.csv`, and `status` must stay consistent with that
  row's `decision` (a catalogue row decided `DO NOT USE` or `UNRESOLVED`
  never gets a capability record).
- `compatible_profiles` lists every `profiles/*.json` `profile` this
  capability is relevant and safe for. There is no cap on how many
  capabilities a profile may include.

Run `python3 scripts/validate.py` after adding or editing a record.
