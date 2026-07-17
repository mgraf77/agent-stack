---
name: secret-safety
description: Use before staging, committing, pushing, or pasting output externally. Scan for credential-shaped strings and likely secret files, and stop to confirm with the user before proceeding if anything is found. Applies even when a filename looks innocuous — check contents, not just names.
license: MIT
---

# Secret Safety

Never commit, push, or externally paste a real credential. This skill is a
mechanical check, not a substitute for judgment — when in doubt, ask before
proceeding.

## What to check, and when

- Before `git add` of more than a few explicitly-named files (and always
  after any broad `git add -A`/`git add .`): run `git status` and look at
  what's actually staged.
- Before `git commit` / `git push`: run `scan-secrets.sh` against the diff or
  changed files.
- Before pasting command output, logs, or file contents into a PR, issue, or
  chat: check it doesn't contain a live credential.

## Patterns this looks for

- Cloud keys: AWS (`AKIA`/`ASIA` + 16 chars), generic `*_SECRET_KEY`,
  `*_API_KEY` assignments with a long opaque value.
- Provider tokens: GitHub (`ghp_`, `gho_`, `github_pat_`), OpenAI/Anthropic-
  style (`sk-`), Slack (`xox[baprs]-`).
- Private key material: `-----BEGIN ... PRIVATE KEY-----` blocks.
- Likely secret files by name: `.env`, `*.pem`, `*.key`, `credentials.json`,
  `id_rsa` and similar, even when tracked under an unrelated-looking name.

## If the scanner flags something

1. Do not silently strip it and move on — confirm with the user whether it's
   a real credential, a fixture/placeholder, or a false positive.
2. If real: unstage it, and if it was already committed, treat rotation/
   history-cleanup as the user's call, not something to do unilaterally.
3. If it's a deliberate test fixture (like this skill's own fixtures),
   placeholder values only — never a live credential — and it should still
   read clearly as fake to a human scanning the file.

## Usage check

`scan-secrets.sh <path>` is a real, runnable grep-based scanner with no paid
dependencies. `check.sh` runs it against the bundled clean/secret fixtures
and confirms detection works before you rely on it.
