---
name: weekly-report
description: Generates a weekly work report by pulling PRs, issues, and commits from a configurable list of repos, then groups them into features / incidents / in-progress. Use when you owe a status update, when you want to see what you actually shipped this week, or when a recruiter asks "what have you been working on?".
---

# weekly-report

Status report generation from your actual git/PR/issue activity.

## Overview

Status reports written from memory are inaccurate. Status reports written
by trawling GitHub manually take an hour you don't have. This skill
generates a draft report from the source-of-truth — your merged PRs,
closed issues, and commits — across a configurable list of repos.

The draft is grouped intelligently (related PRs collapse into one feature
entry; ops issues link to their resolving PRs) and formatted as markdown
you can refine.

## Usage

```
/weekly-report                Generate the report for last week
/weekly-report collect        Print raw collected data only (no grouping)
/weekly-report preview        Show date range only
/weekly-report generate START END    Use a custom date range
```

## Configuration

Create `~/.config/weekly-report/repos.json`:

```json
{
  "author": "your-github-handle",
  "default_range_weekday": "thursday",
  "repos": [
    {
      "alias": "frontend",
      "github": "myorg/web",
      "local": "/Users/me/code/myorg/web",
      "collect": ["pr", "issue", "commit"]
    },
    {
      "alias": "backend",
      "github": "myorg/api",
      "local": "/Users/me/code/myorg/api",
      "collect": ["pr", "issue", "commit"]
    },
    {
      "alias": "ops",
      "github": "myorg/operations",
      "collect": ["issue"]
    }
  ]
}
```

`local` is optional — skip it for ops/issue-tracker repos where you don't
have a checkout.

## Process

### Step 1: Resolve the date range

Default is `[most recent target weekday, today]`. The target weekday is
configurable; pick whichever fits your reporting cadence.

```bash
DOW=$(date +%u)              # 1=Mon..7=Sun
TARGET=4                     # Thursday
if [ "$DOW" -ge "$TARGET" ]; then
  DAYS=$((DOW - TARGET))
else
  DAYS=$((DOW + 7 - TARGET))
fi
START_DATE=$(date -v-${DAYS}d +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)
```

`preview` exits here, just printing the range.

### Step 2: Collect from each repo

Per repo, run only the data sources listed in `collect`. Filter by date
in `jq`, not in the gh search query — the `--search` date qualifier
silently drops results when combined with `--author` or `--state`.

```bash
# Merged PRs you authored
gh pr list -R "$ORG/$REPO" --author "$AUTHOR" --state merged --limit 100 \
  --json number,title,mergedAt,url \
  --jq ".[] | select(.mergedAt >= \"${START_DATE}T00:00:00Z\" and .mergedAt <= \"${END_DATE}T23:59:59Z\")"

# Closed issues assigned to you
gh issue list -R "$ORG/$REPO" --assignee "$AUTHOR" --state closed --limit 100 \
  --json number,title,closedAt,url \
  --jq ".[] | select(.closedAt >= \"${START_DATE}T00:00:00Z\" and .closedAt <= \"${END_DATE}T23:59:59Z\")"

# Open issues (for the "in progress" section)
gh issue list -R "$ORG/$REPO" --assignee "$AUTHOR" --state open \
  --json number,title,url

# Local commits
if [ -n "$LOCAL_PATH" ]; then
  git -C "$LOCAL_PATH" log --author="$AUTHOR" --since="$START_DATE" --until="$END_DATE" \
    --oneline --no-merges
fi
```

If invoked as `/weekly-report collect`, print the raw collected data
grouped by repo and exit.

### Step 3: Group the data

Apply these grouping rules:

1. **Feature work** — PRs whose titles, branches, or linked issues point
   at the same logical change get one entry. (e.g., `#116`, `#117`, `#118`
   all titled "auth rewrite — part N" → one feature line.)

2. **Incident response** — When the ops/issue-tracker repo has an issue
   closed in the window AND there's a resolving PR in another repo
   referencing it, merge them into one entry.

3. **In progress** — Every open issue assigned to you becomes an entry
   in the in-progress section.

### Step 4: Write the markdown

Output to `<report-dir>/<YYYY-MM-DD>-weekly-report.md` (configurable).

Template:

```markdown
# Work — week of {START_DATE} to {END_DATE}

## Timeline

| Date | Item | Links |
|------|------|-------|
| M/DD | Short description | alias#NNN |
| M/DD | Short description | alias#NNN |

## Features

### 1. {feature name} ({date})

One-sentence summary.

- Change 1
- Change 2

**PR**: alias [#NNN](URL), [#NNN](URL)

## Incidents

### 2. {incident name} ({date})

> [ops#NN](URL) / [alias#NN](URL)

**What happened**: ...

**Cause**: ...

**Fix**: ...

**Outcome**: ...

## In Progress

### {workstream}
- [alias#NN](URL) — short status
```

### Step 5: Hand back

Print the file path + a counts summary (`features: N, incidents: N, in progress: N`) and tell the user the draft is ready for review. Don't auto-publish anywhere.

## Tips

- Run this once and treat the output as a draft, not as the final report.
  Grouping is heuristic — you'll always have one or two re-classifications
  to make by hand.
- The first time you run it on a new repo set, expect to tune the alias
  mapping. The aliases show up in the timeline column; keep them short.
- For incident entries, the raw collected data won't tell you "cause" and
  "fix" — you fill those in. The skill's job is to assemble the skeleton.
