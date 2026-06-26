---
name: switch
description: Switches between local project directories with one command and loads minimal context on arrival. Use when you juggle multiple projects on the same machine, when you want to skip typing long paths, or when you want each switch to include the project's branch, status, and CLAUDE.md summary so you know where you are without retracing.
---

# switch

Project teleport with context loading.

## Overview

Anyone working across multiple projects accumulates a directory layout that
goes ten levels deep. `cd` is fine for two projects; with seven you start
losing minutes a day to muscle-memory typos and "wait, which checkout was
this?" recovery.

This skill keeps a JSON map of named projects to absolute paths, and on
each switch it cd's into the right tree plus prints just enough context
(branch, modified files, top of CLAUDE.md) that you don't have to retrace.

## Usage

```
/switch <name>           Switch to the named project
/switch list             Show all registered projects
/switch add <name> <path> Register a new project
```

## Configuration

Project map lives at `~/.claude/project-paths.json`:

```json
{
  "my-frontend": "/Users/me/code/myorg/frontend",
  "my-backend": "/Users/me/code/myorg/backend",
  "blog": "/Users/me/personal/blog",
  "my-frontend-wt": "/Users/me/code/myorg/frontend-worktree"
}
```

Worktree paths get their own entries — keep the same logical name with a
`-wt` suffix so you can flip between main checkout and worktree without
losing the alias.

## Implementation

### Resolve the path

```bash
PROJECT=$1
CONFIG_FILE=~/.claude/project-paths.json

TARGET=$(jq -r --arg p "$PROJECT" '.[$p] // empty' "$CONFIG_FILE")

if [ -z "$TARGET" ]; then
  echo "Unknown project: $PROJECT"
  echo "Registered: $(jq -r 'keys | join(", ")' "$CONFIG_FILE")"
  exit 1
fi

cd "$TARGET"
```

### Print arrival context

```bash
# CLAUDE.md summary (if present)
if [ -f "CLAUDE.md" ]; then
  echo "=== Project Context ==="
  head -30 CLAUDE.md
fi

# Git status
echo ""
echo "=== Git ==="
git branch --show-current
git status -s | head -10
git log --oneline -2
```

Keep the arrival output tight. The point of switching is to start working —
verbose output negates the speed.

## Example

```
/switch my-backend

Switched to: my-backend
Path: /Users/me/code/myorg/backend

=== Project Context ===
NestJS + Prisma backend for the main app...

=== Git ===
* feature/auth-rewrite
M src/auth/auth.service.ts
M src/auth/auth.module.ts
abc1234 wip: rewrite token refresh
def5678 chore: bump prisma to 5.10
```

## Tips

- Register every project you visit more than twice a month.
- Short aliases beat clever ones. `be` > `my-org-backend-v2`.
- Add worktree paths with a `-wt` suffix so flipping is one command.
