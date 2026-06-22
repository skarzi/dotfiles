# Agent Skills Style Guide

Standards for custom AI agent skills authored in
`chezmoi/dot_agents/skills/` and consumed by Claude Code, Codex CLI, Antigravity
CLI, and Cursor.

## 1. Discovery Matrix

Canonical source lives in `chezmoi/dot_agents/skills/`. Chezmoi installs it to
`${HOME}/.agents/skills/`.

| Tool | Scope | Path read by tool | Mode |
| :--- | :--- | :--- | :--- |
| Claude Code | User | `${HOME}/.claude/skills/` | Symlinked |
| Codex CLI | USER | `${HOME}/.agents/skills/` | Native |
| Antigravity CLI | User tier | `${HOME}/.agents/skills/` | Native alias |
| Cursor | User | `${HOME}/.agents/skills/` | Direct read (verify post-apply) |

- Claude Code reads its native path. This repo symlinks each skill from
  `${HOME}/.agents/skills/`.
- Codex CLI USER, Antigravity CLI, and Cursor read the chezmoi-installed path
  directly.

Antigravity documents the user-tier `${HOME}/.agents/skills/` alias in
[Discovery tiers](https://antigravity.google/docs/skills/#discovery-tiers).

## 2. agentskills.io Spec

Full spec: <https://agentskills.io/specification>.

Each skill is a directory containing `SKILL.md`.

### Required Frontmatter

- **`name`**: Kebab-case skill name.
  - 64 chars max.
  - Must match the parent directory name.
  - Must match regex `[a-z0-9][a-z0-9-]*`.
  - No leading or trailing hyphen.
- **`description`**: Trigger-focused summary.
  - 1024 chars max.
  - Written to surface activation triggers.

### Optional Frontmatter

- **`license`**: License identifier or license text reference.
- **`compatibility`**: Compatibility notes, 500 chars max.
- **`metadata`**: Free-form map.
- **`allowed-tools`**: Experimental, space-separated tool list.

### Body

- Write standard Markdown after the YAML frontmatter delimiter.
- Keep body content focused on instructions needed after activation.
- Use relative paths for local `scripts/`, `references/`, and `assets/`.

### Progressive Disclosure

- Only `name` and `description` are always in context.
- The full body loads only after the skill activates.
- Put trigger terms in `description`, not only in the body.

## 3. Naming Conventions

- Use kebab-case: `migration-review`, not `migration_review`.
- Keep names 64 chars max.
- Do not use leading or trailing hyphens.
- Match the skill directory exactly:

    ```text
    chezmoi/dot_agents/skills/migration-review/SKILL.md
    name: migration-review
    ```

## 4. Description Writing

Follow the agentskills.io guide:
[Optimizing Descriptions](https://agentskills.io/skill-creation/optimizing-descriptions).

- State what the skill does in direct trigger language.
- Name the artifacts, tools, repos, commands, and concepts it covers.
- Use specific verbs and nouns, such as `review`, `validate`, `migrate`, and
  `shellspec`.
- Assume the assistant only sees `description` until activation.
- Make the description earn its context slot.

## 5. Validation

<!-- TODO(skarzi): introduce skills validation (e.g. skills-ref or
     equivalent) and wire a `make lint-skills` target. -->

- Run markdown lint for docs changed with `make lint-fix-markdown -- <file>`.

## 6. Directory Layout

See `chezmoi/dot_agents/skills/README.md` for the layout cheatsheet.

## Summary Checklist

- [ ] `name` is kebab-case, 64 chars max, and matches the directory.
- [ ] `description` is trigger-focused and 1024 chars max.
- [ ] Optional frontmatter stays within documented limits.
- [ ] Skill body uses standard Markdown after frontmatter.
- [ ] Local helper paths are relative to the skill directory.
