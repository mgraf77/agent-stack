# Release and Rollback Checklist

Applies to Agent Stack itself. No hosted release pipeline — this is a plain
git tag plus a manually written note, run by a human.

## Cutting a release

1. Confirm `main` only contains merged, reviewed PRs — no direct pushes.
2. Confirm the public-repository boundary holds: no secrets, credentials,
   customer data, or project-private context anywhere in the diff since
   the last release (see root `README.md`).
3. Add an entry to `release/CHANGELOG.md` describing what changed and why,
   in plain language a project owner can act on without reading the diff.
4. Tag the release commit: `git tag vX.Y.Z && git push origin vX.Y.Z`.
5. Note the exact commit SHA in the changelog entry — the SHA, not just
   the tag, is what receipts pin against.

Use semantic-ish versioning: bump the patch for fixes/docs, the minor for
new profiles/skills that are additive, the major for anything that changes
or removes something a project may already be pinned to.

## Rolling back a project's pin

If a newly pinned release causes a problem in a product repo:

1. Identify the last known-good tag/commit — check the `sourceRelease`
   field in that product repo's committed `sync-receipt.json` history, or
   `release/CHANGELOG.md` here.
2. Check out this repo (Agent Stack) at that earlier tag/commit locally.
3. Re-run sync against the product repo, pointed at that release:
   ```
   node scripts/sync.mjs --profile <same-profile-name> --mode apply --out-root /path/to/product-repo --release <earlier-tag>
   ```
   This overwrites the current synced skills and receipt with the
   known-good ones.
4. Run `node scripts/doctor.mjs --out-root /path/to/product-repo` to
   confirm the rollback landed clean (no drift, no leftover files).
5. Commit the rollback in the product repo like any other change, with a
   one-line reason — it goes through the same review as anything else.

## Rolling back Agent Stack itself

Tags are append-only. Never delete or force-move a published tag.

1. If a release is bad, publish a new patch release that reverts the
   problematic change, rather than rewriting history.
2. Mark the bad tag as deprecated in `release/CHANGELOG.md` with a pointer
   to the fixed release, so anyone reading old receipts knows to move
   forward, not back, to the fix.

## Both cases

- Every promotion and rollback stays reviewable on GitHub — no
  auto-merge, no direct push to `main`, no silent overwrite of a project's
  synced files without a commit recording it.
