# Sync/release receipts

Each file here is a copy or archive of one `sync-receipt.json` — the
exact receipt `scripts/sync.mjs --mode apply` writes into an adapter's
export target directory, validated against
`schemas/sync-release-receipt.schema.json` and re-verifiable with
`scripts/doctor.mjs`.

There is exactly one receipt format in this repo: `receiptVersion`,
`profile`, `sourceRelease`, `adapter` (`id`, `targetDir`), `generatedAt`,
`skills` (each with `id`, `files[]` of `{path, sha256}`, and a
`skillChecksum`), and a `receiptChecksum` covering the whole receipt.
`python3 scripts/validate.py` recomputes `skillChecksum` and
`receiptChecksum` from the recorded per-file hashes the same way
`scripts/doctor.mjs` does, so a hand-edited or corrupted receipt is
caught without re-reading the exported skill files.

`example-core-codex-sync-receipt.json` is a worked example with
internally-consistent but synthetic file content and checksums — not a
real export — kept here so the schema and its checksum recomputation
stay exercised in local validation.
