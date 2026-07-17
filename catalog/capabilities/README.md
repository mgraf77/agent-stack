# Capability records

Each file here is one curated, reusable capability derived from a row in
`catalog/repositories.csv`, validated against
`schemas/capability-record.schema.json`.

- Filename must equal the record's `id` plus `.json`.
- `source.canonical_repo_or_product` must match a row in
  `catalog/repositories.csv`, and `status` must stay consistent with that
  row's `decision` (a catalogue row decided `DO NOT USE` or `UNRESOLVED`
  never gets a capability record).
- `compatible_profiles` lists every `profiles/*.json` `profile_id` this
  capability is relevant and safe for. There is no cap on how many
  capabilities a profile may include.

Run `python3 scripts/validate.py` after adding or editing a record.
