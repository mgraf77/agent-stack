# Free-first policy

Agent Stack itself must run on free/open-source tools and local files.
The only expected recurring cost is existing ChatGPT and Claude usage.

## Rules

1. No capability, profile, script, or validation step may require a paid
   service, hosted database, paid automation platform, or paid observability
   product to work at all.
2. A catalogued source may still be `PILOT`-worthy even if it has a paid
   tier, as long as the free/open-source path is what gets adopted here.
3. `scripts/validate.py` and every other local script must run with
   nothing beyond a standard Python (or Node, or POSIX shell) install —
   no API keys, no network calls, no signup.
4. If a real project need later requires a paid dependency, that decision
   is made and paid for in the product repository, not defaulted into
   this shared stack.

## Enforcement

`scripts/validate.py` checks structure and consistency, not billing, so
this policy is enforced by review: a PR that adds a capability, profile,
or script depending on a paid runtime should be rejected or reworked
before merge.
