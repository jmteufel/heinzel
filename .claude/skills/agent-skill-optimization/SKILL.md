---
name: agent-skill-optimization
description: Use when writing, creating, or optimizing skills or agents —
  frontmatter format, auto-invoke vs manual-only, writing style, prompt vs
  script tradeoffs, extracting skills from documents or conversations.
disable-model-invocation: true
---

## Format

Path: `<ai-tool-dir>/skills/<name>/SKILL.md`

`<ai-tool-dir>` is the AI tool's config directory — `.claude`, `.agents`,
`.vscode`, etc., depending on the tool.

```yaml
---
name: skill-name
description: <trigger condition, 1–2 sentences>
disable-model-invocation: true  # omit for auto-invoke
---
```

## Auto-Invoke vs Manual-Only

**Auto-invoke** — omit flag. Loads when description matches context.
Use for conditions always active in a session (OS detected, EFI mentioned).

**Manual-only** — add `disable-model-invocation: true`. User types
`/skill-name`. Use for on-demand workflows, reference material, and
any skill that could trigger destructive or hard-to-reverse actions.
When in doubt, default to manual-only.

## Description Field

Trigger condition only — not a summary of the body.

- "Load when..." or "Use when..."
- Cover the *when*, not the *what*
- Never repeat it in the body

## Body Conventions

- No H1 title — `name` frontmatter is the title
- No intro paragraph
- Lead with most-used content
- Wrap at 80 characters

## Writing Style

Fewer tokens = faster, cheaper, clearer. Write like instructions, not prose.

- Bullets over paragraphs
- No filler ("In order to...", "You should...", "It is important that...")
- Direct nouns and verbs
- Cut qualifiers that add no meaning

## `## Also Load` Pattern

```
## Also Load

- `/skill-name` — reason. Qualifier for when it applies.
```

Place at bottom. Always include the qualifier.

## References Subdirectory

Bulk content (tables, templates, long examples) goes in `references/`:

```
<ai-tool-dir>/skills/<name>/
├── SKILL.md
└── references/
    └── detail.md
```

Keeps `SKILL.md` lean. Model loads references on demand.

## Prompt vs Script

**Prompt** — analysis, judgment, variable workflow, infrequent use.

**Script** — deterministic steps, no mid-process decisions, frequent use.
Typical savings: ~3000 → ~500 tokens per run.

```
<ai-tool-dir>/skills/<name>/
├── SKILL.md         # ~60 lines: context + script call
└── scripts/
    └── <action>.sh  # all logic; a skill may have multiple scripts
```

## Extracting from a Document

1. Read the source; identify what triggers needing it → description
2. Strip title and intro; convert prose to bullets
3. Update stale cross-references (other docs → skills where applicable)
4. Remove or archive the source
5. Update any project docs that referenced it

## Extracting from a Conversation

1. Identify the repeatable pattern — what would trigger this again
2. Extract the steps; discard one-off context (issue numbers, reasons
   specific to that session)
3. Decide prompt vs script
4. Write `SKILL.md`; verify it reads cleanly without conversation context
