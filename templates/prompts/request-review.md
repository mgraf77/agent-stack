# Prompt: Ask Codex (or Claude Code) for independent review

Use this against a tool that did **not** write the PR.

```
Independently review PR #<NUMBER> in this repository:
<PASTE PR LINK>

Read the actual diff yourself — do not treat the PR author's summary as
ground truth, and do not assume tests passing means the change is correct.

Report:
1. Correctness bugs or edge cases the diff misses.
2. Anything out of the issue's stated scope.
3. Anything risky or hard to reverse.
4. Whether you'd merge this as-is, or what would need to change first.

Be direct. If it looks fine, say so briefly — don't invent issues to seem
thorough.
```
