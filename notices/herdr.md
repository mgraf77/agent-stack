# Third-party notice: Herdr

## Source

- Project: Herdr — "agent multiplexer that lives in your terminal"
- Repository: https://github.com/ogulcancelik/herdr
- Documentation: https://herdr.dev
- Agent skill reference (upstream, not copied here): https://herdr.dev/docs/agent-skill/
- Maintainer: ogulcancelik

## License

Herdr is dual-licensed:

- **GNU Affero General Public License v3.0 (or later)** for open-source use, and
- a **separately negotiated commercial license** for organizations that cannot
  comply with AGPL's terms (per the upstream repository's own description).

Agent Stack does not relicense, sublicense, or alter these terms. Anyone who
installs and runs Herdr is bound by whichever of the two licenses applies to
their use.

## Version guidance

- Latest tagged release observed at the time this notice was written:
  `v0.7.4` (released 2026-07-15; observed 2026-07-17).
- Do not hardcode this version anywhere it would rot silently. When wiring a
  project to Herdr, record the actual installed `herdr --version` output in
  that project's own setup notes, and re-check https://herdr.dev or the
  GitHub releases page for updates periodically. This repository does not
  pin or bundle a specific Herdr build.

## What this repository contains — and does not

Agent Stack integrates with Herdr **by reference only**:

- `integrations/herdr/` documents how to install Herdr locally and how it
  wires into this stack's profiles.
- `skills/herdr-workspace/` is an independently written skill describing
  workspace conventions (pane roles, status handoff) for an agent operating
  inside a Herdr-managed pane.
- `profiles/herdr.yaml` selects that skill and this integration for a
  project that has chosen to use Herdr.

None of these files contain, vendor, mirror, fork, or embed any line of
Herdr's own source code, its `SKILL.md`, its CLI implementation, or its
socket protocol implementation. They reference publicly documented,
externally observable interfaces (the `herdr` CLI, and the `HERDR_ENV`,
`HERDR_SOCKET_PATH`, `HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`, and
`HERDR_PANE_ID` environment variables that Herdr itself injects into
processes running inside its managed panes) the same way any end user or
script author would.

## AGPL boundary

This repository:

- never imports, links against, statically or dynamically embeds, or
  redistributes any Herdr binary or source file;
- never modifies Herdr;
- only shells out to an independently installed `herdr` executable through
  its documented CLI/socket interface, exactly as an ordinary user's
  terminal session would.

Under that boundary, Agent Stack's own integration code is not a derivative
work of Herdr and does not itself carry AGPL's network-copyleft obligation.
If this integration is ever changed to bundle, statically link, or modify
Herdr source, that assessment must be redone before merging.

## Installation stays external

Herdr is never installed, downloaded, or executed as part of this
repository's setup. Install it yourself, on your own machine, using one of
Herdr's own published methods (curl script, Homebrew, `mise`, or a GitHub
release binary — see https://herdr.dev). This repository assumes Herdr may
or may not be present and must keep working either way.

## Platform note

Herdr's Linux and macOS builds are the stable, supported path. Windows
native builds are labeled beta/preview by the upstream project. See
`integrations/herdr/README.md` for the concrete recommendation
(WSL2 on Windows).
