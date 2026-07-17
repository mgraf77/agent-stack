---
name: orientation
description: Use at the start of any task in a repo you have not just fully explored — read the repo's own docs, note stated ownership boundaries and constraints, and check current git state before planning or editing. Prevents guessing at conventions the repo already documents, and prevents clobbering in-progress work.
license: MIT
---

# Orientation

Before writing a plan or touching files, spend one short pass confirming what the
repo already tells you, instead of inferring it from file names or memory.

## Steps

1. **Read the repo's own instructions first.** Root `README.md`, `AGENTS.md` /
   `CLAUDE.md`, `CONTRIBUTING.md`, and any package-level docs in the directory
   you're about to change. Treat these as authoritative over general habits.
2. **Note ownership boundaries.** If the task or a doc states "you own only
   these paths" or "do not modify X", write that down before planning — it
   constrains every later step, including which files a diff may touch.
3. **Note hard constraints.** License restrictions, "no paid services", "no
   secrets", "no production actions" — anything stated as a rule rather than a
   suggestion. These override convenience later.
4. **Check current git state before assuming a clean slate.** Run `git status`
   and `git log --oneline -10` on the relevant branch. Uncommitted changes or
   unfamiliar branches usually mean in-progress work — investigate before
   overwriting it (see repo guidance on destructive git operations).
5. **Summarize in one short paragraph** before planning: purpose of this repo/
   area, boundaries you must respect, constraints that apply, and current
   state. This is for your own planning, not a deliverable — keep it to a
   sentence or two unless asked for more.

## When to skip

Skip re-orienting on every single message in a long session — do it once when
you start a new task, switch to an unfamiliar part of the repo, or resume
after a long gap. Re-reading the same docs every turn is wasted work.

## Usage check

`check.sh` runs against any target repo path (defaults to `.`) and reports
which orientation docs it finds and the current git state, so you can confirm
the skill's checklist maps to something real before relying on it.
