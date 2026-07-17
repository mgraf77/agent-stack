# Notice: skills/browser-qa

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| gstack | https://github.com/garrytan/gstack | main, observed 2026-07-17 | MIT |

## What was used

The general concept behind gstack's `/browse` (real-browser command
execution) and `/qa`/`/qa-only` (QA-lead role that drives the app and fixes
what it finds) commands: verify UI behavior by actually driving a browser,
not by reading the diff. No gstack file, command text, or code was copied.

## Local modifications

The process checklist (start app, real browser, golden path, edge cases,
console check, capture evidence) and `templates/smoke.spec.template.js` — a
minimal Playwright script skeleton using the standard `playwright` npm
package's public API (`chromium.launch`, `page.goto`, etc., which are
third-party public API surface, not gstack's code) — are original to this
repository. `check.sh` only syntax-checks the template with `node --check`;
it does not launch a browser and assumes no running app.
