# Agent Stack

A shared, cross-project capability stack for Michael's projects.

## Purpose

Agent Stack makes reusable skills, profiles, evaluations, and agent-operating patterns available across AccentOS, MichaelOS, BetIQ, and future projects without turning any product repository into a dumping ground.

This repository is the reusable capability layer. Product facts, customer data, credentials, task state, and project-specific workflows stay in their own repositories.

## Principles

- **Use what already exists.** Copy, adapt, and pin compatible upstream material; do not rebuild mature capability from scratch.
- **No arbitrary skill cap.** A profile can include as many skills as a real project needs. Selection is based on compatibility, safety, and usefulness—not an invented number.
- **Free-first.** The stack itself uses free/open-source tools and local files. The expected recurring cost is existing ChatGPT and Claude usage only. Do not introduce paid infrastructure, hosted databases, paid automation, or paid observability by default.
- **Small active surface, not an artificial limit.** Profiles expose what is useful for the current task and can grow freely; avoid loading irrelevant instructions just because they exist.
- **GitHub is work truth.** Issues, branches, commits, pull requests, and releases remain canonical for engineering work.
- **No secrets or business data.** Never store credentials, cookies, browser profiles, customer/vendor exports, or raw production data here.
- **No auto-merge or autonomous production authority.** Every promotion and project update stays reviewable and reversible.
- **Copy only compatible material.** Record source, version, license, and local changes for every imported asset.

## What belongs here

- curated skill packages and their tests
- project profiles
- source catalogue and decisions
- lockfiles and release receipts
- local sync/doctor scripts
- policies and evaluation fixtures
- small, licensed upstream slices or independent adaptations

## What does not belong here

- full clones of agent frameworks
- project roadmaps, issues, or PR state
- production connectors or credentials
- a second memory/task system
- business data
- paid SaaS dependencies required for normal use

## Initial implementation lanes

1. Foundation: catalogue, profiles, policies, validation, and release structure.
2. Upstream curation: import/adapt compatible gstack, ECC, OpenSpec, Superpowers, Cavekit, and related material.
3. Codex/Claude sync: one canonical skill source exported to each supported local skill path with receipts.
4. Herdr: optional local terminal orchestration integration; never vendor Herdr code.
5. Evaluations: activation, non-activation, security, permission, and rollback checks.

## Herdr

[Herdr](https://github.com/ogulcancelik/herdr) is an optional free local terminal multiplexer for Claude Code and Codex. Keep it as an external local tool with an integration profile and wrapper instructions. Do not copy or vendor its AGPL code into this repository.

## Public-repository boundary

This repository is currently public. Until its visibility is changed, commit only material that is safe to publish: open-source-compatible code, generic instructions, public source metadata, and synthetic fixtures. Do not add project-specific private context.
