# Herdr integration

Herdr (https://github.com/ogulcancelik/herdr, docs at https://herdr.dev) is
an optional, free, local terminal multiplexer for running and coordinating
multiple Claude Code / Codex sessions in separate panes. This directory
holds Agent Stack's *integration wiring* for it — never Herdr's own code.

See `notices/herdr.md` for source, license (AGPL-3.0, with a separate
commercial license option), and the AGPL boundary this integration relies
on.

## What "integration" means here

Nothing in this repository installs, launches, or depends on Herdr being
present. A project opts in by:

1. Installing Herdr locally, on your own machine, using one of Herdr's own
   published methods — curl script, Homebrew, `mise`, or a GitHub release
   binary (see https://herdr.dev). Record the `herdr --version` you
   installed in your own project notes; this repository does not pin one.
2. Selecting the `herdr` profile (`profiles/herdr.yaml`) for that project,
   which pulls in the `herdr-workspace` skill
   (`skills/herdr-workspace/SKILL.md`).
3. Running Claude Code or Codex *inside* a Herdr-managed pane, as you
   normally would with Herdr.

If Herdr is not installed, or a session is not running inside a
Herdr-managed pane, the `herdr-workspace` skill is inert: it must decline
to issue any Herdr-specific control commands and the agent behaves like it
would in any ordinary terminal.

## The ownership boundary

- Herdr owns: the `herdr` binary, its CLI, its socket API, its pane/tab/
  workspace model, and the `HERDR_ENV=1` proof-of-ownership environment
  variable it injects into panes it manages.
- Agent Stack owns: the decision to *use* that CLI from inside a pane,
  workspace conventions for how multiple agents share a Herdr session
  (coordinator pane, isolated worker panes, one test/log pane), and a
  blocked/working/done handoff convention layered on top.

Agent Stack never reimplements, forks, or patches any part of Herdr itself.
When exact CLI subcommand syntax is needed, defer to `herdr --help` and
https://herdr.dev/docs — those can change independently of this
integration, and this integration must not go stale by hardcoding
assumptions about them.

## Safety and cost boundary

- Fully local and free: no API keys, no hosted control plane, no server
  Agent Stack or Herdr requires you to run remotely.
- No automatic production authority: nothing here grants an agent running
  inside Herdr any additional merge, deploy, or production permission
  beyond what its own harness and the project's normal review process
  already allow. Herdr coordinates terminal panes; it does not grant scope.
- Optional and reversible: removing Herdr, or simply not running inside a
  Herdr pane, must not break any other skill, profile, or workflow in this
  repository.

## Windows note

Herdr's Linux and macOS builds are the stable path. Windows native builds
are beta/preview upstream. **On Windows, run Herdr (and Claude Code/Codex)
inside WSL2** for a stable experience; treat the native Windows build as
experimental until upstream calls it stable.

## Verification

See the "Verification checklist" section in
`skills/herdr-workspace/SKILL.md` for a manual/synthetic check that the
`HERDR_ENV` gate, pane roles, and handoff convention behave as documented.
