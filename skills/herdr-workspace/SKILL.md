---
name: herdr-workspace
description: Workspace conventions for an agent (Claude Code or Codex) running inside a Herdr-managed terminal pane — coordinator/worker pane roles, a blocked/working/done handoff protocol, and safe use of the local herdr CLI. Refuses to issue any Herdr control command unless HERDR_ENV=1 proves the current pane is actually owned by Herdr.
---

# Herdr workspace conventions

Herdr (https://github.com/ogulcancelik/herdr, https://herdr.dev) is an
optional, free, local terminal multiplexer that can run several Claude
Code / Codex sessions in separate panes and let them coordinate. This
skill does not vendor or reimplement Herdr — see
`notices/herdr.md` and `integrations/herdr/README.md` for the source,
license, and ownership boundary. This skill only describes how an agent
should behave *while running inside* a Herdr-managed pane.

## Hard gate: prove you're actually inside Herdr

Before doing anything in this skill that talks to Herdr (its CLI or its
local socket), check the environment:

```
HERDR_ENV=1
```

Herdr injects `HERDR_ENV=1` (plus `HERDR_SOCKET_PATH`, `HERDR_WORKSPACE_ID`,
`HERDR_TAB_ID`, and `HERDR_PANE_ID`) into every process running inside a
pane it manages. That variable is the only proof that this session is
actually running inside a Herdr-owned pane rather than an arbitrary
terminal that merely happens to have this skill loaded.

- If `HERDR_ENV` is not set, or is not exactly `1`: **stop.** Say plainly
  that this session is not running inside a Herdr-managed pane, do not run
  any `herdr` CLI command or touch the Herdr socket, and fall back to
  behaving like a normal terminal session. Do not guess, retry, or attempt
  to "enable" Herdr — that decision belongs to Herdr and the human who
  launched it, not to this skill.
- If `HERDR_ENV=1` is set: you may use the `herdr` CLI to interact with
  other panes in this workspace, subject to the conventions below. For
  exact subcommand syntax, run `herdr --help` or see
  https://herdr.dev/docs — this skill intentionally does not hardcode
  Herdr's CLI surface, since that is Herdr's to change.

## Pane topology

A Herdr workspace under this convention has exactly these pane roles:

1. **Coordinator pane** (one) — holds the overall task breakdown, assigns
   work to worker panes, reads their status, and decides what's next. The
   coordinator is the only pane that should spawn or reassign workers.
2. **Worker panes** (one or more, isolated) — each worker owns one
   self-contained unit of work (a file, a subtask, a branch) and must not
   reach into another worker's files or in-progress edits. Workers report
   status; they do not silently take on additional scope.
3. **Test/log pane** (one) — a shared pane (or tailed log file) where
   build, test, and lint output lands so the coordinator and any worker can
   check real signal without re-running the same command in every pane.

Keep the topology this small on purpose: one coordinator, N isolated
workers, one shared test/log surface. Don't add more shared panes than
that — extra shared state is exactly what turns into cross-worker
interference.

## Handoff protocol: blocked / working / done

Each worker pane keeps its status in one visible place — its pane title
(`herdr` lets you set/read pane metadata; see `herdr --help`) or a small
status line at the top of its own scrollback — using exactly one of:

- `working: <one-line summary of current step>`
- `blocked: <what's needed and from whom>` — e.g. a decision from the
  coordinator, output from another worker, or a human answer. A blocked
  worker does not spin; it states the blocker and waits.
- `done: <one-line summary of what changed>`

The coordinator polls or reads worker panes (via the `herdr` CLI's
pane-read capability) rather than having workers push into the
coordinator's own pane. When a worker reports `blocked`, the coordinator
resolves the blocker or explicitly reassigns before the worker proceeds.
When a worker reports `done`, the coordinator verifies against the
test/log pane before marking that unit of work closed.

## Claude Code in Herdr

- Start Claude Code normally inside the pane Herdr spawned for you; do not
  launch a second nested multiplexer inside that pane.
- Use the `HERDR_ENV=1` gate above before touching the `herdr` CLI from
  within a Claude Code session — the same rule applies whether you got
  here via a slash command, a skill, or a subagent.
- When spawning subagents for isolated units of work, prefer mapping each
  subagent's scope to one worker pane rather than fanning out multiple
  independent concerns inside a single pane.

## Codex in Herdr

- Same gate, same topology: check `HERDR_ENV=1` before any Herdr-specific
  action, and treat the pane you were started in as your one unit of
  worker scope unless you are the coordinator.
- Codex sessions should write their status using the same
  `working:` / `blocked:` / `done:` convention so a mixed Claude
  Code + Codex workspace stays legible to whichever agent is coordinating.

## Boundaries this skill will not cross

- No API keys or hosted control plane: everything above is local process
  and terminal coordination. This skill never asks for or stores a
  credential.
- No required remote server: Herdr itself runs locally; this skill assumes
  no network service beyond that.
- No automatic production authority: pane coordination is not merge,
  deploy, or release authority. A `done` status means "ready for the usual
  review," not "ship it."
- No action outside `HERDR_ENV=1`: restated because it's the one rule this
  skill must never bend.

## Verification checklist

Manual/synthetic checks to confirm this skill behaves as documented
(no production Herdr session required for the first three):

1. **Gate refuses without the flag.** Unset `HERDR_ENV` (or set it to
   anything other than `1`) and ask the agent to do something
   Herdr-specific (e.g. "list the other panes"). Confirm it refuses and
   states it is not running inside a Herdr-managed pane, without
   attempting any `herdr` command.
2. **Gate opens with the flag.** Run `HERDR_ENV=1 <your agent CLI>` (a
   synthetic export is enough; a real Herdr pane is not required to check
   the gate logic itself) and confirm the agent is now willing to discuss
   or attempt Herdr CLI usage.
3. **Topology stays small.** Ask the agent to plan a multi-pane workspace
   for a 3-part task and confirm it proposes exactly one coordinator, one
   pane per isolated unit of work, and one shared test/log pane — not an
   arbitrary or growing number of shared panes.
4. **Handoff vocabulary is exact.** Ask a worker-role agent to report
   status and confirm it uses one of `working:`, `blocked:`, `done:`
   verbatim, with a one-line summary, not free-form prose.
5. **Live smoke test (requires Herdr installed).** Install Herdr locally,
   start a workspace with one coordinator and two worker panes plus a
   test/log pane, and confirm: `echo $HERDR_ENV` prints `1` in every
   managed pane; a worker set to `blocked:` is left alone by other workers;
   a worker set to `done:` gets checked against the test/log pane before
   the coordinator moves on.
6. **Absence is safe.** With Herdr not installed at all, confirm the rest
   of the project's profiles and skills still load and function —
   this skill's absence-of-Herdr path must never be a hard dependency for
   anything else in the repository.
