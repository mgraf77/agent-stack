# Notice: skills/orientation

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| gstack | https://github.com/garrytan/gstack | main, observed 2026-07-17 | MIT |
| Everything Claude Code (ECC) | https://github.com/affaan-m/ECC | v2.0.0, observed 2026-07-17 | MIT |

## What was used

Neither source has a single dedicated "orientation" skill; the concept —
read a project's own instructions and current state before acting — is
implicit across gstack's phased workflow commands and ECC's status/context
discipline (`ecc status`, session/context handling). No file, prose, or code
was copied from either project.

## Local modifications

Entirely independent write-up: the checklist (read docs, note ownership
boundaries, note constraints, check git state, summarize) and `check.sh`
were authored from scratch for this repository's own conventions (notably
`AGENTS.md`'s emphasis on reading repo docs and respecting stated
boundaries).
