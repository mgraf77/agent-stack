# Operator Onboarding

This is the practical guide for running Agent Stack day to day. It assumes
you (Michael) are working across product repos (AccentOS, MichaelOS, BetIQ,
future ones) with Claude Code, Codex, ChatGPT, and GitHub.

For deeper detail, see:
- `docs/operator-flow.md` — how requests move between tools, and how skills
  get selected without you picking them
- `docs/pilot.md` — the first three-task pilot
- `release/CHECKLIST.md` — cutting and rolling back a release
- `templates/prompts/` — copy-paste prompts

## 1. Pinning a release and consuming a profile

Agent Stack is consumed by **deterministic copy**, not by cloning it into a
product repo or symlinking it. Nothing here runs as a live service.

1. Agent Stack cuts tagged releases (`vX.Y.Z`) on `main`. See
   `release/CHECKLIST.md`.
2. A product repo picks one profile that matches its project type (e.g. a
   "product-build" profile). Profiles live under `profiles/<name>/` in this
   repo and are out of scope for this doc — they are populated by a separate
   lane.
3. To adopt or refresh a pin, ask Claude Code or Codex (inside the product
   repo) to copy the chosen profile's skill files from the pinned Agent
   Stack tag into the product repo's local skill path, then write a receipt.
   The receipt format is in `templates/receipt.json`; a filled example is in
   `examples/receipt.example.json`.
4. Commit the copied files and the receipt together in the product repo.
   That commit is the pin — it fully determines what release/profile/commit
   the project is running, with no external lookup required.

There is no sync daemon and no CLI to install. "Pinning" is: pick a tag,
copy files, write a receipt, commit. Re-running the same prompt against a
newer tag is how you upgrade; re-running it against an older tag is how you
roll back (see `release/CHECKLIST.md`).

## 2. Asking for work without choosing skills manually

You do not select skills per task. The profile already decided which skills
are available in the product repo when it was pinned. Your job per task is
just to describe the task in plain language — see
`templates/prompts/start-task.md`.

Claude Code / Codex reads the skills already synced into the repo (per the
pinned profile) and self-activates whichever are relevant to what you asked
for, the same way any other skill or instruction file is picked up. If a
task needs a capability the current profile doesn't include, that's a
signal to refresh the pin (step 3 above) or file an issue against the
catalog/profile lanes — not something to solve by hand-picking skills mid
task.

## 3. Who does what

| Tool | Role |
|---|---|
| **ChatGPT** | Thinking partner. Scopes the task, writes the issue/prompt text, decides what and why. No repo write access. |
| **Claude Code** | Primary implementer. Takes a bounded issue, implements it in a branch, tests, commits, opens a PR. |
| **Codex** | Independent second opinion. Reviews Claude's PRs against the actual diff (not Claude's own summary), or independently implements/remediates when asked. |
| **GitHub** | System of record. Issues, branches, commits, PRs, and releases are the canonical history — not a separate tracker. |
| **MichaelOS (later)** | Future personal control plane that may tie these together. Not required and not built yet — see the no-overengineering rule below. |

The loop for a normal task: ChatGPT (or you) writes the issue → Claude Code
implements → Codex reviews → you merge on GitHub. Any tool can flip roles
(Codex can implement, Claude Code can review) — the roles above are the
default assignment, not a hard rule.

## 4. Free-first rule

Normal operation must not require anything beyond your existing ChatGPT and
Claude usage plus GitHub. No paid dashboards, hosted services, or paid
automation are required to pin a release, run a task, or complete the
pilot. If a catalog entry is marked PILOT/ADOPT and costs money beyond that,
it is optional and evaluated separately — never a prerequisite.

## 5. No-overengineering rule

Do not stand up a dashboard, hosted service, database, or a universal CLI
before the first three-task pilot (`docs/pilot.md`) is complete and
reviewed. Everything in this doc works with: a text editor, git, GitHub,
and a chat with Claude Code or Codex. If the pilot proves the flow is too
manual, that's a real finding to act on afterward — not something to
pre-solve now.
