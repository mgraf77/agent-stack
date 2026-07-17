# Agent Stack Instructions

## Mission

Build a reusable, free-first capability stack for multiple projects by curating and adapting compatible upstream material. Do not recreate mature systems from scratch when a compatible source can be copied, configured, or wrapped.

## Repository boundary

- Keep product code, customer data, credentials, task state, and private knowledge out of this repository.
- Keep this repository public-safe until its visibility changes.
- Do not vendor full frameworks, binaries, or dependencies.
- Do not introduce paid services as a requirement for normal use.
- Do not add automatic production actions, auto-merge, credential storage, or background execution.

## Source reuse

Before adding an imported asset:

1. Record canonical URL, version/commit, license, and local modifications.
2. Copy only the smallest useful compatible slice.
3. Preserve notices/attribution where required.
4. Add a test or concrete verification path.
5. Keep original source and local adaptation clearly separate.

## Profiles and skills

- There is no arbitrary cap on the number of skills a profile may contain.
- Include every skill that is relevant and compatible with the selected project.
- Do not load irrelevant skills just because they are available.
- Keep canonical skills in `skills/<name>/SKILL.md`.
- Treat a profile as a deterministic selection of skills, adapters, and policies.
- Profile delivery must use deterministic copies and receipts, never cross-repository symlinks.

## Herdr

Herdr is optional local orchestration tooling. Do not vendor Herdr code. Only use its CLI/socket controls when running inside a Herdr-managed terminal and the environment proves that ownership.

## Change discipline

- One focused concern per branch and pull request.
- Do not edit unrelated paths.
- Run relevant validation before claiming completion.
- Include a concise handoff with changed paths, source material, validation, and remaining risks.
