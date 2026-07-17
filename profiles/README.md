# Profiles

Each file here is a deterministic selection of capabilities and policies
for one project or shared lane, validated against
`schemas/project-profile.schema.json`.

- Filename must equal the record's `profile_id` plus `.json`.
- `capabilities` lists `catalog/capabilities/*.json` ids. There is no
  arbitrary cap: include every capability that is relevant and compatible
  with the project, and nothing that isn't.
- Delivery to a product repository must use a deterministic copy plus a
  receipt (see `schemas/sync-release-receipt.schema.json`), never a
  cross-repository symlink.

Current profiles: `core`, `product-build`, `accentos`, `michaelos`,
`experimental`.

Run `python3 scripts/validate.py` after adding or editing a profile.
