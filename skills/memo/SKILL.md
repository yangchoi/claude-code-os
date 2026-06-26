---
name: memo
description: Shares short memos across parallel Claude Code sessions so handoffs don't require copy-paste. Use when working in multiple sessions, when finishing one piece of work that the next session needs to pick up, or when you want a lightweight scratchpad that survives across sessions without polluting a real project.
---

# memo

A tiny key-value-ish store for cross-session handoff notes.

## Overview

When you work in multiple Claude Code sessions in parallel — one writing code,
one reviewing, one investigating — you often finish something in session A
that session B needs to know about. The natural move is to paste a status
update into the other terminal, but that's friction that adds up.

This skill saves short memos to a single JSON file under `~/.claude/` that
any session can read. It's not a knowledge base, not a journal, not a task
tracker. It's just enough state to hand off context cleanly.

## Usage

```
/memo save <content>     Save a new memo
/memo list               Show all memos (alias: /memo)
/memo delete <id>        Delete one memo by ID
/memo clear              Wipe all memos
```

## How It Works

Memos live at `~/.claude/session-memos.json` as a flat array of
`{id, memo, time}` objects. Each save appends; each delete removes by ID.

### save

```bash
MEMO_FILE=~/.claude/session-memos.json
[ ! -f "$MEMO_FILE" ] && echo "[]" > "$MEMO_FILE"

jq --arg memo "$CONTENT" --arg time "$(date -Iseconds)" \
  '. += [{"id": (. | length + 1), "memo": $memo, "time": $time}]' \
  "$MEMO_FILE" > tmp && mv tmp "$MEMO_FILE"
```

### list

```bash
jq -r '.[] | "[\(.id)] \(.time | split("T")[0]) - \(.memo)"' "$MEMO_FILE"
```

### delete

```bash
jq --argjson id "$ID" 'del(.[] | select(.id == $id))' "$MEMO_FILE" > tmp && mv tmp "$MEMO_FILE"
```

### clear

```bash
echo "[]" > "$MEMO_FILE"
```

## Example

Session A finishes an API endpoint:

```
/memo save Backend done: POST /api/auth/verify. Frontend needs to call with x-token header.
```

Session B picks up:

```
/memo list
[1] 2026-06-26 - Backend done: POST /api/auth/verify. Frontend needs to call with x-token header.
```

## Tips

- Save what the next session needs to know, not what you just did. Future-self
  isn't reading this for nostalgia.
- Include the artifact (endpoint, file path, branch name), not just a vibe.
- Clear weekly. Stale memos pollute the list and you start ignoring it.
