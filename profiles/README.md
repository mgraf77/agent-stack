# Profiles

Each file here is a deterministic selection of exportable skills,
catalogue capabilities, and policies for one project or shared lane,
validated against `schemas/project-profile.schema.json`.

- Filename must equal the record's `profile` value plus `.json`.
- `profile` and `skills` are the exact contract `scripts/sync.mjs`
  reads: `skills` lists `skills/<id>/` directories (each with a
  `SKILL.md`) to export for real, into each adapter's target directory.
  There is no arbitrary cap: include every skill that is relevant and
  compatible with the project, and nothing that isn't. Ids must be
  kebab-case and unique.
- `capabilities` lists `catalog/capabilities/*.json` ids — source
  catalogue/provenance references for context. They are not exported by
  sync and are not a substitute for a real skill; an actually-needed
  capability should have a matching `skills/<id>/SKILL.md` and appear in
  `skills` too.
- Delivery to a product repository happens via `scripts/sync.mjs
  --mode apply`, which writes a deterministic copy plus a
  `sync-receipt.json` per adapter (see
  `schemas/sync-release-receipt.schema.json`) — never a cross-repository
  symlink.

Current profiles: `core`, `product-build`, `accentos`, `experimental`.

Run `python3 scripts/validate.py` after adding or editing a profile.
