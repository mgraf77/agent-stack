# Real-skill promotion fixtures

`secret-safety-broken.promotion.json` is a negative control for the
`evals/run.sh --skill` route (see `evals/README.md`). It is a copy of
`skills/secret-safety/promotion.json` with exactly one field changed
(`untrusted_content_handling: false`), used via `--manifest` against the
real `skills/secret-safety/` files:

```bash
bash evals/run.sh --skill skills/secret-safety \
  --manifest evals/fixtures/skills/secret-safety-broken.promotion.json
```

Expected result: every check passes except `prompt_injection`, proving the
`--skill` gate correctly rejects a real skill whose manifest doesn't declare
untrusted-content handling, without needing a second copy of the skill's
files.
