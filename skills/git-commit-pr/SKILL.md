---
name: git-commit-pr
description: Runs the commit and PR creation flow with a secrets check and a consistent style. Use when the user says "commit", "push", "open a PR", or anything that mutates git history. Includes pre-commit pattern checks for common credential leaks.
disable-model-invocation: true
argument-hint: "[commit|pr] [message]"
---

# git-commit-pr

Commit and PR creation with a secrets check on the way out.

## Why This Exists

Two failure modes show up often enough to deserve their own skill:

1. **Credentials in commits.** A `.env` file slipping into a commit, an API
   key pasted into a fixture file, a service account JSON dragged into a
   PR. Most of these are caught by pattern-matching before the commit,
   not after.
2. **Inconsistent commit and PR style.** Without conventions, history rots
   into a stream of "fix", "update", "wip" messages. Conventional Commits
   keep the log scannable.

This skill enforces both before either reaches the remote.

## Commit Workflow

```
Checklist:
- [ ] git status — see what's staged and unstaged
- [ ] git diff — review every line
- [ ] Secrets check — no credentials, no .env, no PEM
- [ ] git add <specific files> — never `git add -A`
- [ ] git commit -m "type(scope): message"
```

```bash
git status
git diff
# Manually stage only the files you mean to commit
git add path/to/file
git commit -m "type(scope): subject line"
```

Use specific paths in `git add`. `git add -A` is how `.env` files end up
in commits — the staging list grows past what you actually meant to stage,
and the diff review doesn't catch what's already staged.

## PR Workflow

```
Checklist:
- [ ] Verify current branch is the one you intend to push
- [ ] git log --oneline -5 — does the commit list match the PR scope?
- [ ] git push -u origin <branch>
- [ ] gh pr create with descriptive title + body
```

```bash
git log --oneline -5
git push -u origin <branch>
gh pr create --title "subject" --body "$(cat <<'EOF'
## Summary
- bullet 1
- bullet 2

## Test plan
- [ ] step 1
- [ ] step 2
EOF
)"
```

## Commit Types

| Type | Use for |
|------|---------|
| `feat` | new feature |
| `fix` | bug fix |
| `docs` | documentation only |
| `refactor` | code change with no behavior change |
| `test` | tests added or changed |
| `perf` | performance improvement |
| `chore` | tooling, deps, build, no production code change |

Scope is optional: `feat(auth): add token refresh`. Use scope when the
codebase has natural modules; skip it when scope would be artificial.

## Secrets Check

Block the commit if any of these match:

### Files

```
.env
.env.*
*.pem
*.key
*credentials*
*secret*
serviceAccount*.json
```

### Patterns inside files

```
sk-[a-zA-Z0-9]{20,}           # OpenAI / Anthropic-style
AKIA[A-Z0-9]{16}              # AWS access key ID
ghp_[a-zA-Z0-9]{36}           # GitHub personal access token
gho_[a-zA-Z0-9]{36}           # GitHub OAuth token
xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+ # Slack bot token
-----BEGIN.*PRIVATE KEY-----   # Any private key block
```

If a check fires, stop. Don't commit. Help the user move the secret to the
right place (env var, secrets manager) and rotate it if it ever existed
in a remote.

## Style Conventions

The defaults this skill applies (override per project by reading the
project's CLAUDE.md or contributor docs):

- **Commit messages**: English, Conventional Commits, imperative mood
- **PR title**: short and descriptive (under 70 chars), no ticket numbers
  in the title (put them in the body)
- **PR body**: Summary + Test plan, both bulleted
- **No AI signature lines**: no "Co-Authored-By: Claude", no "Generated
  with Claude Code" footer
- **No emoji** unless the project explicitly uses them

## Configuration

| Setting | Where |
|---------|-------|
| Default reviewer / assignee | `~/.agents/WHOAMI.md` if present, else none |
| Per-project style overrides | project's CLAUDE.md or CONTRIBUTING.md |

## Tips

- Read the diff. Every time. The most common bad commit is the one that
  contains a change you didn't realize was staged.
- One logical change per commit. If you can't write the message without
  "and", split the commit.
- Push only the branch you mean to push. `git push --all` is the same
  class of mistake as `git add -A`.
