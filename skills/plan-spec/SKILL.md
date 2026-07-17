---
name: plan-spec
description: Use before implementing any non-trivial change (multi-file, ambiguous, or risky) to write a short spec — goal, constraints, interfaces, invariants, tasks — so there is a checkable target before code is written. Skip for one-line or fully-specified fixes; scale the spec to the task instead of using a fixed template size.
license: MIT
---

# Plan Spec

A spec is a cheap way to catch a wrong plan before it becomes a wrong diff.
Size it to the task: a trivial fix needs a sentence, a multi-file feature
needs the full template.

## When to write one

- Write a spec: new feature, cross-file refactor, anything with more than one
  reasonable interpretation, anything touching a public interface or shared
  state.
- Skip it: a one-line bug fix, a typo, a fully-specified task with no
  ambiguity ("rename X to Y everywhere").

## Structure (`templates/SPEC.template.md`)

- **Goal** — one or two sentences: what outcome, for whom, why now.
- **Constraints** — things the solution must respect (existing APIs, perf,
  license, "no new dependency", explicit ownership boundaries).
- **Interfaces** — what changes at the boundary: function signatures, CLI
  flags, file formats, endpoints. Skip if nothing external changes.
- **Invariants** — properties that must stay true after the change (data
  shape, backwards compatibility, security properties). These are what you
  check against later, not aspirations.
- **Tasks** — the ordered list of concrete steps. Check items off as you go;
  this list is the plan, not a separate backlog system.

## Where it lives

Keep the spec inline — in the issue/task description, a PR description, or a
scratch note for the session. Do not stand up a second tracking system next
to the repo's existing issue/PR flow; the spec is a planning artifact for
this change, not a permanent record.

## Drift check

Before calling the work done, re-read the spec's Invariants and Interfaces
sections against the actual diff. Anything that drifted either needs a code
fix or an explicit, called-out spec update — never a silent mismatch.

## Usage check

`check.sh` validates that a filled-in spec file contains the required
section headers, so you can confirm a spec is complete enough to build from.
