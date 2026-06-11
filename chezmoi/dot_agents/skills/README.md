# Agent Skills

Canonical agentskills.io source for custom agent skills. Chezmoi installs it to
`~/.agents/skills/`, then skills are symlinked into `~/.claude/skills/`.

```text
<skill-name>/
  SKILL.md
  scripts/     # Optional helpers.
  references/  # Optional source docs.
  assets/      # Optional binary or visual assets.
```

## Consumed By

| Tool        | Path                | Notes               |
| ----------- | ------------------- | ------------------- |
| Claude Code | `~/.claude/skills/` | Symlinked from here |
| Codex CLI   | `~/.agents/skills/` | USER scope, native  |
| Gemini CLI  | `~/.agents/skills/` | User-tier alias     |
| Cursor      | `~/.agents/skills/` | Direct read         |

`SKILL.md` requires YAML frontmatter:

```yaml
---
name: my-skill
description: Trigger-focused summary.
---
```

- `name`: kebab-case, 64 chars max, must match directory name.
- `description`: 1024 chars max.

See `.agents/skills-styleguide.md` for full guidance.
