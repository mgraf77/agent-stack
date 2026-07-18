# Pilot: first real `product-build` profile sync

Date: 2026-07-18
Commit used: `43885dea221a65bf60bff296ac35ef515cfd96d6` (`main`, unreleased —
no tag exists yet, so `sync.mjs`'s default `sourceRelease` of `unreleased`
was used, suffixed with the commit SHA for traceability)
Environment: Node v22.22.2, Python 3.11.15, bash, jq

## Scope

Ran the real `product-build` profile against this repo's own merged
`skills/` content, syncing into a fresh temporary output root outside the
repo (not a product repo, and nothing under it was committed here). This
follows `docs/onboarding.md` §1–2 and closes issue #13.

## Commands and results

All commands were run from the repo root, `OUT_ROOT` pointed at an empty
temporary directory created for this pilot only.

1. Dry-run sync
   ```
   node scripts/sync.mjs --profile product-build --mode dry-run --out-root "$OUT_ROOT"
   ```
   Result: exit 0. Plan listed all 7 `product-build` skills (browser-qa,
   evidence-before-done, handoff, orientation, plan-spec, pr-feedback,
   secret-safety) with per-skill checksums and both adapter targets
   (`.claude/skills`, `.agents/skills`).

2. Apply sync
   ```
   node scripts/sync.mjs --profile product-build --mode apply --out-root "$OUT_ROOT" --release "unreleased@43885dea221a65bf60bff296ac35ef515cfd96d6"
   ```
   Result: exit 0. Same 7 skills written deterministically to both adapter
   target directories under `$OUT_ROOT`, each with a `sync-receipt.json`.

3. Doctor (drift check)
   ```
   node scripts/doctor.mjs --out-root "$OUT_ROOT"
   ```
   Result: exit 0. `{"adapter":"claude-code","ok":true,...}` and
   `{"adapter":"codex","ok":true,...}` — no drift, no symlinks.

4. Repo validator
   ```
   python3 scripts/validate.py
   ```
   Result: exit 0. `Checked: 1 catalogue, 11 capabilities, 5 profiles. OK:
   all records valid.`

5. Every curated skill's `check.sh` (the 7 skills in `product-build`)
   ```
   bash skills/browser-qa/check.sh
   bash skills/evidence-before-done/check.sh skills/evidence-before-done/fixtures/sample-good.txt
   bash skills/handoff/check.sh
   bash skills/orientation/check.sh
   bash skills/plan-spec/check.sh
   bash skills/pr-feedback/check.sh
   bash skills/secret-safety/check.sh
   ```
   Result: all 7 exit 0 / OK, including `secret-safety`'s two-fixture
   detection pair (clean fixture no false positive, planted-secret fixture
   detected).

6. Eval harness self-test
   ```
   bash evals/run.sh
   ```
   Result: exit 0. Harness self-scan passed; all 36 check outcomes (6
   checks × 6 synthetic fixtures) matched
   `evals/fixtures/expected_outcomes.json`.

## Limitations

- No tagged release exists yet (`git tag` is empty), so this pilot pinned
  against the current `main` commit rather than a released `vX.Y.Z` — the
  first real `release/CHECKLIST.md` cut is still open work.
- The sync target was a scratch directory, not an actual product repo, so
  this validates the tooling end-to-end but not a real product repo's
  reaction to the synced skills (e.g. no live task was run against them).
  That remains the subject of `docs/pilot.md`'s three-task pilot.
