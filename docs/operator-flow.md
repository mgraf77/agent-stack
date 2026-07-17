# Operator Flow

How a task actually moves through the tools, end to end.

## Request → implementation → review → merge

1. **Frame the task.** Use ChatGPT (or write it yourself) to turn a vague
   want into a bounded GitHub issue: what's in scope, what's explicitly out
   of scope, and what "done" looks like. Keep issues small enough to land
   in one PR.
2. **Implement.** Open Claude Code (or Codex) against the product repo and
   hand it the issue with `templates/prompts/start-task.md`. It works on a
   branch, using whatever skills the repo's pinned profile already synced
   in — you don't name skills, you describe the task.
3. **Review.** Once a PR exists, ask the *other* tool for an independent
   review with `templates/prompts/request-review.md`. The point of using
   the other tool is that it has no stake in its own summary of the work —
   it has to read the diff.
4. **Merge.** You make the merge call on GitHub. Nothing here auto-merges.
5. **If something breaks or a session gets interrupted**, resume with
   `templates/prompts/resume-session.md` instead of re-describing the whole
   task from scratch.

## Why you don't pick skills

Skill selection happens once, at pin time, not once per task:

- A profile (`profiles/<profile_id>.json`) is a curated, named list of
  capabilities for a project type — e.g. `core` vs. `product-build`. There
  is no arbitrary cap on how many it can include; scope comes from picking
  the right profile, not from a limit.
- Pinning a profile (see `docs/onboarding.md` §1) runs
  `node scripts/sync.mjs --profile <id> --mode apply --out-root <product-repo>`,
  which replaces `.claude/skills/` and `.agents/skills/` in the product
  repo with exactly that profile's skills and writes a `sync-receipt.json`
  into each, recording exactly what was copied.
- `node scripts/doctor.mjs --out-root <product-repo>` is the drift check:
  it recomputes checksums against the receipt and fails loudly if the
  synced skills were hand-edited, partially removed, or left stale from an
  earlier profile. Run it before trusting a pin, not after something looks
  wrong.
- From then on, every Claude Code / Codex session in that repo already has
  the relevant skills on its skill path. You just describe the task.

If a task keeps needing something outside the current profile, that's
signal the profile is wrong for this project — fix it by refreshing the
pin against an updated profile, not by manually wiring a skill in for one
session.

## Division of responsibility (detail)

- **ChatGPT** is the planning and governance layer: scoping, drafting
  issue text, and thinking through tradeoffs before any code is touched.
  Treat its output as a draft issue, not an instruction Claude Code/Codex
  must follow verbatim.
- **Claude Code** is the default implementer for bounded, in-repo work: one
  issue, one branch, one PR. It should stay inside the paths the issue
  actually calls for.
- **Codex** is the default independent reviewer, and a fallback
  implementer when you want a second attempt or when Claude Code is stuck.
  Never let the same tool review its own PR — that defeats the point.
- **GitHub** holds all durable state: issues, branches, PRs, review
  comments, and releases. If it isn't on GitHub, it isn't real work yet.
