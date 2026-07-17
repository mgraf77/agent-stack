---
name: legacy-only
description: Synthetic fixture skill that exists only to prove stale skills are removed when a profile changes. Used only by distribution sync tests.
---

# Legacy Only (fixture)

Selected by the `with-extra` synthetic fixture profile but not by `demo`.
`tests/determinism.sh` applies `with-extra` then `demo` to the same output
root and asserts this skill's exported directory is removed.
