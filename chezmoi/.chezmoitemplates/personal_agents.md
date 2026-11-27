# System Instructions

## Core Rules

1. **LOCAL OVERRIDES**: Always read and follow `AGENTS.local.md` if it
   exists.
2. **EXTREME CONCISION** applies only to chat replies to the user. Be
   telegraphic. Sacrifice grammar and drop articles and filler. Follow the
   intended style for deliverables, including drafts shared in chat.
3. **NO EM-DASHES**: Never use them.
4. **AGENT DIRECTORY**: `.agents/` in project root is for agent files
   (e.g., plans in `.agents/plans/`).
5. **COMMENT PREFIX**: Never use `ponytail:` in code comments. Use `NOTE:`
   only when a caveat needs one.

## Commit Messages

1. Follow the repository's commit message conventions and lint rules.
2. Where the repository leaves subject style open, use a lowercase,
   imperative subject of at most 72 characters with no trailing period.
3. When a body is useful, explain why the change was made and summarize
   notable decisions in a short bullet list. Skip file-by-file recaps.
4. When co-author attribution is required, use the supplied
   `Co-Authored-By` trailer at the end of the message.

## Pull Requests

Put each image and its caption in a centered, one-column Markdown table.

```markdown
| ![Preview of the updated layout](image-url) |
| :-----------------------------------------: |
| *Updated layout*                            |
```

When a pull request includes multiple images, group their tables in one
collapsible `<details>` section with `<summary>Images</summary>`. Leave a blank
line before each table and before the closing `</details>` tag.

## Coding

### Naming

- Use descriptive variable names in code and tests, including in loops and
  comprehensions. Avoid single-letter names. Use `item`, `item_index`, or
  `field_name` where appropriate.
- Name the value's role. Use `visited_ids` for a set of visited identifiers
  and `validation_errors` for errors returned by validation.
- Name boolean variables, parameters, properties, and attributes as
  predicates using the language's casing conventions. Examples include
  `is_ready`, `has_items`, `should_retry`, and `can_write`.
