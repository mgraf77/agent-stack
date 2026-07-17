# Pilot: `product-build` profile sync, doctor, validate, and evals

Closes #13. First end-to-end run of the real `product-build` profile
against this repository's merged `skills/` content, with results recorded
here instead of committed generated output.

- **Commit used:** `43885dea221a65bf60bff296ac35ef515cfd96d6` (no tagged
  release exists yet, so the commit SHA was passed as `--release`).
- **Output root:** a fresh temporary directory outside the repo. No
  `.agents/skills` or `.claude/skills` were written to or committed in
  this repo.

## Commands and results

```
node scripts/sync.mjs --profile product-build --mode dry-run \
  --out-root "$OUT" --release 43885dea221a65bf60bff296ac35ef515cfd96d6
```
Result: plan printed for 7 skills (browser-qa, evidence-before-done,
handoff, orientation, plan-spec, pr-feedback, secret-safety) across both
adapters (`claude-code`, `codex`). Exit 0.

```
node scripts/sync.mjs --profile product-build --mode apply \
  --out-root "$OUT" --release 43885dea221a65bf60bff296ac35ef515cfd96d6
```
Result: wrote `.claude/skills/` and `.agents/skills/` under `$OUT`, one
directory per skill plus a `sync-receipt.json` per adapter. Exit 0.

```
node scripts/doctor.mjs --out-root "$OUT"
```
Result: `{"adapter":"claude-code","ok":true,"problems":[]}` and
`{"adapter":"codex","ok":true,"problems":[]}`. Exit 0.

```
python3 scripts/validate.py
```
Result: `Checked: 1 catalogue, 11 capabilities, 5 profiles. OK: all
records valid.` Exit 0.

```
for d in skills/*/; do [ -f "$d/check.sh" ] && bash "$d/check.sh"; done
```
Result: all 7 curated skills with a `check.sh` passed —
browser-qa, handoff, orientation, plan-spec, pr-feedback, and
secret-safety with no arguments (each defaults to its own bundled
fixture); evidence-before-done run explicitly against its own
`fixtures/sample-good.txt` (its `check.sh` requires a target file, unlike
the others, since it scans an arbitrary handoff/report file rather than a
self-contained fixture). `herdr-workspace` has no `check.sh` and is not
selected by `product-build`, so it was not exercised here.

```
bash evals/run.sh
```
Result: harness self-scan passed, and all 36 check outcomes (6 checks x 6
synthetic fixtures) matched `evals/fixtures/expected_outcomes.json`.
`RESULT: all 36 check outcomes matched expectations.` Exit 0.

## Limitation

No tagged release exists on this repository yet, so the sync receipts in
this pilot reference the commit SHA above via `--release` rather than a
version tag. Re-run once a first release is cut to confirm receipts carry
a stable release identifier instead.
