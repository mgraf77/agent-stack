# Notice: skills/repo-context

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| Repomix | https://github.com/yamadashy/repomix | v1.16.1, observed 2026-07-17 | MIT |

## What was used

The general concept behind Repomix — pack a repository (or a scoped
subset of it) into one deterministic, ordered, single-file bundle for
sharing with a reviewer or an LLM, with a secret scan on the assembled
output before it leaves the local machine and no online upload for a
sensitive repo. This mirrors the exact rationale already recorded for the
`repomix-context-export` decision in `catalog/repositories.csv` and
`catalog/capabilities/repomix-context-export.json` — this skill is what
turns that existing capability record into something an agent can
actually run. No Repomix file, CLI output format, or code was read or
copied; `pack-context.sh` is an independent, much smaller, grep/find/git-
ls-files-based implementation covering only local Markdown bundling, not
Repomix's config system, remote-repo cloning, or output-format options.

## Local modifications

- Determinism is enforced directly (sorted `LC_ALL=C` file order, no
  timestamps) rather than configured, since this skill has exactly one
  output shape.
- The secret scan reuses this repository's own `skills/secret-safety/
  scan-secrets.sh` (grep-based, no Gitleaks binary dependency) instead of
  Gitleaks, since `secret-safety` already fills that role locally; the
  packer degrades to a warning (not a hard failure) if that sibling
  script isn't present in a given checkout, so `repo-context` doesn't
  hard-depend on another skill's file to run.
- `check.sh` and its fixtures (`fixtures/sample-project/`,
  `fixtures/sample-project-secret/`) are original to this repository. The
  planted fake credential (`AKIAIOSFODNN7EXAMPLE`) is AWS's own public
  example access key, the same placeholder already used by
  `skills/secret-safety/fixtures/sample-secret.txt` — never a live
  credential.
