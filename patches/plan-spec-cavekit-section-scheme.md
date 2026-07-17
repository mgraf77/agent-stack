# Patch: plan-spec section scheme (from Cavekit)

- **Source**: https://github.com/JuliusBrussee/cavekit
- **Version observed**: v4 (main branch), observed 2026-07-17
- **License**: MIT
- **File referenced**: `FORMAT.md` (structural section scheme, not prose)

## What was kept

Cavekit's `FORMAT.md` defines a fixed spec section scheme identified by
letter: §G (Goal), §C (Constraints), §I (Interfaces), §R (Research,
optional), §V (Invariants), §T (Tasks), §B (Bugs, auto-populated via
backpropagation). `skills/plan-spec/templates/SPEC.template.md` keeps the
same ordering and intent for five of those seven sections: Goal,
Constraints, Interfaces, Invariants, Tasks.

A named, ordered checklist of section *roles* (as opposed to specific
wording, symbols, or table syntax) is a thin structural idea with limited
independently-expressive content — this patch calls it out explicitly
rather than silently treating it as fully independent, in keeping with this
repo's "record every modification" rule.

## What was changed

- Dropped §R (Research) and §B (Bugs) — out of scope for a lightweight
  starter spec; a full backprop-from-bugs workflow is a larger feature this
  starter batch doesn't attempt.
- Dropped the single-letter §-notation and Cavekit's pipe-table encoding
  (chosen there for token efficiency) in favor of plain Markdown `##`
  headings with prose bullets, since this repo's spec is meant to be read
  by a human reviewer in an issue/PR, not optimized for minimum token count.
- All heading text, bullet wording, and surrounding guidance in
  `SKILL.md`/`SPEC.template.md` is independently written; no Cavekit prose
  was copied.
