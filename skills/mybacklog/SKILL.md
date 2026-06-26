---
name: mybacklog
description: Tiny markdown-backed personal TODO list with add/done/remove operations. Use when you want a backlog that lives alongside your Claude Code setup, not in a third-party app, and that any session can read and mutate without leaving the terminal.
---

# mybacklog

A markdown TODO list that any Claude Code session can read and mutate.

## Overview

You don't need Linear or Notion to track personal work-in-progress. A single
markdown file with `[ ]` and `[x]` checkboxes is enough, and it has one
advantage no SaaS can match: every Claude Code session can see it without
auth, integrations, or context switching.

This skill keeps the file at `~/.agents/TODO.md` and provides four
operations. That's the entire system.

## Usage

```
/mybacklog                Show the current list
/mybacklog add <text>     Append a new item
/mybacklog done <n>       Mark item N as done (moves [ ] to [x])
/mybacklog remove <n>     Delete item N entirely
```

## File Format

```markdown
# TODO

## Pending
- [ ] 1. Write the lessons essay
- [ ] 2. Investigate the rate limit weirdness
- [ ] 3. Reply to the recruiter email

## Done
- [x] Set up the new monitor
- [x] Renew the domain
```

The format is plain enough that you can also edit by hand when the CLI is
too much ceremony — open the file, change a `[ ]` to `[x]`, save.

## Implementation

1. Read `~/.agents/TODO.md` (create empty if missing)
2. Dispatch on first argument:
   - none → print the file
   - `add <text>` → append to "## Pending" with the next number
   - `done <n>` → flip `[ ]` to `[x]` and move under "## Done"
   - `remove <n>` → delete the matching line
3. Write back

## Tips

- Don't backlog grocery lists here. This is for work items that benefit from
  every session knowing about them.
- Prune the Done section weekly. It's a record, not a museum.
- When you have more than ~15 pending items, the list is broken. Triage,
  don't keep stacking.
