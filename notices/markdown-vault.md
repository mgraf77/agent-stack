# Notice: skills/markdown-vault

## Sources referenced

| Source | URL | Version observed | License |
|---|---|---|---|
| Obsidian Skills | https://github.com/kepano/obsidian-skills | main, ~46 commits, observed 2026-07-17 | MIT |
| LLM Wiki gist | https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f | created 2026-04-04, observed 2026-07-17 | No explicit license attached to the gist; idea reimplemented independently, no text copied |

## What was used

- From Obsidian Skills: the general concept of Markdown notes carrying
  YAML frontmatter metadata and `[[wiki-link]]`-style cross-references
  between notes, and linting that those references resolve. This was
  flagged as a follow-up candidate in the first curation batch (see
  `notices/README.md`'s "Policy applied in this batch" note: "a vault-
  markdown skill from obsidian-skills... once the profile layer asks for
  them"). No Obsidian Skills file, plugin code, or prose was copied — this
  skill implements only frontmatter + link-resolution linting with plain
  `awk`/`grep`/`sed`, not Obsidian's Bases/Canvas features or its plugin
  API.
- From the LLM Wiki gist: the general pattern of splitting a knowledge
  base into raw, immutable captured sources versus a separately
  maintained, linked wiki layer built from them — reimplemented here as
  the `raw`/`wiki` frontmatter `kind` distinction and the `sources` field
  a wiki note uses to cite the raw note(s) it's derived from. The gist is
  an idea document, not software; its structure and wording were not
  copied — only the raw/wiki split concept was reimplemented in this
  repository's own words.

## Local modifications

The exact frontmatter schema (`title`, `kind`, `tags`, `sources`), the
two starter templates (`templates/RAW.template.md`,
`templates/WIKI.template.md`), `lint-notes.sh`'s two-pass frontmatter-then-
link-resolution check, and `check.sh` with its clean/broken fixture vaults
are original to this repository.
