# Prompt: Start a bounded implementation task

Copy, fill in the brackets, paste into Claude Code (or Codex) inside the
product repo.

```
You are implementing GitHub issue #<NUMBER> in this repository:
<PASTE ISSUE TITLE + BODY OR LINK>

Scope:
- Only touch what this issue requires. If you find unrelated problems,
  note them at the end instead of fixing them here.
- Use whatever skills are already available in this repo's synced profile;
  don't ask me which skill to use.

When you're done:
1. Run the relevant tests/linters and fix failures caused by your change.
2. Commit with a clear message.
3. Push to a new branch and open a PR against the default branch.
4. Summarize: what changed, how you verified it, and any risks or
   follow-ups I should know about.

Do not merge the PR yourself.
```
