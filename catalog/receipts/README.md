# Sync/release receipts

Each file here records one profile sync or release event, validated
against `schemas/sync-release-receipt.schema.json`.

- Filename must equal the record's `receipt_id` plus `.json`.
- `profile` must match a `profiles/*.json` `profile_id`.
- Write a receipt whenever a profile is actually delivered (synced or
  released) to a product repository, after `python3 scripts/validate.py`
  passes.

`example-2026-07-17-core-sync.json` is a worked example, not a real sync;
it exists to keep the schema exercised in CI/local validation.
