# Notice: skills/secret-safety

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| Everything Claude Code (ECC) | https://github.com/affaan-m/ECC | v2.0.0, observed 2026-07-17 | MIT |
| gstack | https://github.com/garrytan/gstack | main, observed 2026-07-17 | MIT |

## What was used

- From ECC: the general concept of a pre-submit secret-pattern check (their
  `beforeSubmitPrompt` hook and AgentShield integration describe detecting
  `sk-`, `ghp_`, `AKIA`-shaped strings in prompts/commits). The specific
  regex families these token prefixes belong to are public, provider-
  documented formats (GitHub's `ghp_`/`gho_`/`github_pat_` prefixes, AWS's
  `AKIA`/`ASIA` key-ID prefixes, Slack's `xox*` prefixes, the common `sk-`
  convention), not expression copied from ECC. No ECC code or file was
  read or copied.
- From gstack: the general concept behind `/careful`/`/guard` — pause and
  confirm before a risky action rather than proceeding silently — applied
  here to "found a possible secret" instead of destructive commands. No
  gstack file or text was copied.

## Local modifications

`scan-secrets.sh` is an original grep-based implementation written for this
repository (see the script's own header comment). Fixture values in
`fixtures/sample-secret.txt` use only well-known, publicly-documented
placeholder values (e.g. AWS's own example key `AKIAIOSFODNN7EXAMPLE` from
AWS's public documentation, and an all-zero fake GitHub token) — never a
real credential.
