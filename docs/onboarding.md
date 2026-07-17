# Operator Onboarding

This is the practical guide for running Agent Stack day to day. It assumes
you (Michael) are working across product repos (AccentOS, BetIQ, future
ones) with Claude Code, Codex, ChatGPT, and GitHub.

For deeper detail, see:
- `docs/operator-flow.md` — how requests move between tools, and how skills
  get selected without you picking them
- `docs/pilot.md` — the first three-task pilot
- `release/CHECKLIST.md` — cutting and rolling back a release
- `templates/prompts/` — copy-paste prompts
- `templates/sync-receipt-reference.md` — what `sync-receipt.json` contains
  and why

## 1. Pinning a release and consuming a profile

Agent Stack is consumed by **deterministic copy**, run locally via
`scripts/sync.mjs` — not by cloning it into a product repo, symlinking it,
or running it as a service.

1. Agent Stack cuts tagged releases (`vX.Y.Z`) on `main`. See
   `release/CHECKLIST.md`.
2. A product repo picks one profile that matches its project type —
   `profiles/<name>.json` in this repo, where the filename matches that
   record's `profile` field (e.g. `core`, `product-build`; see
   `profiles/README.md`). There is no arbitrary skill cap: a profile
   includes every skill that's relevant to that project type, and nothing
   else.
3. From a local checkout of this repo at the tag you're pinning to, preview
   the sync, then apply it against the product repo:

   ```
   node scripts/sync.mjs --profile <profile-name> --mode dry-run --out-root /path/to/product-repo
   node scripts/sync.mjs --profile <profile-name> --mode apply   --out-root /path/to/product-repo --release <tag>
   ```

   `apply` replaces `.claude/skills/` and `.agents/skills/` in the product
   repo with exactly the selected profile's skills (deterministic copy, no
   symlinks) and writes a `sync-receipt.json` into each of those
   directories recording the profile, the release, and a checksum per
   skill file. See `templates/sync-receipt-reference.md` for the shape and
   `examples/sync-receipt.example.json` for a filled example.
4. In the product repo, commit the exported skill directories together
   with their `sync-receipt.json` files. That commit is the pin — it fully
   determines what release/profile the project is running, with no
   external lookup required.

Re-running `apply` against a newer tag is how you upgrade; re-running it
against an older tag is how you roll back (see `release/CHECKLIST.md`).

## 2. Checking for drift: doctor

```
node scripts/doctor.mjs --out-root /path/to/product-repo
```

`doctor` re-walks the committed `.claude/skills/` and `.agents/skills/`
directories, recomputes each file's checksum, and compares it against what
`sync-receipt.json` recorded. It exits non-zero and lists the problem if:
a skill file was hand-edited after sync, a skill listed in the receipt is
missing, a skill directory on disk isn't in the receipt (stale, left over
from a prior profile), the receipt itself was hand-edited, or a target
directory is a symlink.

Run it before starting a task, to confirm the pin you're relying on is
still intact, and as part of reviewing any PR that touched
`.claude/skills/` or `.agents/skills/` directly. `doctor` never writes
anything — if it flags drift, fix it with `sync.mjs --mode apply` (step 3
above), not by hand-editing the flagged files.

## 3. Asking for work without choosing skills manually

You do not select skills per task. The profile already decided which skills
are available in the product repo when it was pinned. Your job per task is
just to describe the task in plain language — see
`templates/prompts/start-task.md`.

Claude Code / Codex reads the skills already synced into the repo (per the
pinned profile) and self-activates whichever are relevant to what you asked
for, the same way any other skill or instruction file is picked up. If a
task needs a capability the current profile doesn't include, that's a
signal to refresh the pin against a different/updated profile (§1 above) —
not something to solve by hand-picking a skill in for one session.

## 4. Who does what

| Tool | Role |
|---|---|
| **ChatGPT** | Planning and governance. Scopes the task, writes the issue/prompt text, decides what and why, and is where you think through tradeoffs before code is touched. Treat its output as a draft issue, not an instruction Claude Code/Codex must follow verbatim. |
| **Claude Code** | Primary implementer. Takes a bounded issue, implements it in a branch, tests, commits, opens a PR. |
| **Codex** | Independent second opinion. Reviews Claude's PRs against the actual diff (not Claude's own summary), or independently implements/remediates when asked. |
| **GitHub** | System of record. Issues, branches, commits, PRs, and releases are the canonical history — not a separate tracker. |

The loop for a normal task: ChatGPT (or you) writes the issue → Claude Code
implements → Codex reviews → you merge on GitHub. Any tool can flip roles
(Codex can implement, Claude Code can review) — the roles above are the
default assignment, not a hard rule.

## 5. Free-first rule

Normal operation must not require anything beyond your existing ChatGPT and
Claude usage plus GitHub. `sync.mjs`/`doctor.mjs` are dependency-free local
Node scripts, not a hosted service, daemon, or paid tool. No paid
dashboards, hosted services, or paid automation are required to pin a
release, run a task, or complete the pilot. If a catalog entry is marked
PILOT/ADOPT and costs money beyond that, it is optional and evaluated
separately — never a prerequisite.

## 6. No-overengineering rule

Do not stand up a dashboard, hosted service, database, or a universal CLI
before the first three-task pilot (`docs/pilot.md`) is complete and
reviewed. Everything in this doc works with: a text editor, git, GitHub,
the local `sync.mjs`/`doctor.mjs` pair, and a chat with Claude Code or
Codex. There is also no arbitrary cap on how many skills a profile can
carry — scope is controlled by picking the right profile, not by an
artificial limit. If the pilot proves the flow is too manual, that's a
real finding to act on afterward — not something to pre-solve now.
