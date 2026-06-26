---
name: whoami
description: Maintains a developer profile (stack, preferences, experience) at ~/.agents/WHOAMI.md so Claude doesn't re-ask the same setup questions every session. Auto-activates when a response would otherwise need to guess your stack, your style preferences, or your experience level.
---

# whoami

Persistent developer profile so Claude knows who it's working with.

## Overview

Without a profile, Claude either re-asks "which framework do you use?" every
new session or silently guesses. Both are wrong defaults. This skill keeps
a stable profile file that gets auto-loaded the moment a response would
otherwise depend on assumptions about your stack or preferences.

## When to Use

The skill fires automatically when:

- The user's stack or preferences are about to shape the response
- Code style decisions need a default (tabs vs spaces, quotes, line length)
- Recommendations depend on experience level
- A new project needs sensible defaults (language, framework, test runner)

Explicit invocation works too:

- "Show my profile"
- "Update my profile"
- "Add Rust to my languages"

## Workflow

### First run: build the profile

If `~/.agents/WHOAMI.md` doesn't exist, ask a focused set of questions and
write the profile. Use `AskUserQuestion` to group related questions — don't
fire one question per topic, that's exhausting.

Cover:

1. **Identity** — name/handle, role (backend / frontend / full-stack / DevOps)
2. **Languages** — primary (1–3), secondary, preferred
3. **Frameworks** — backend, frontend, libraries
4. **Environment** — OS, editor/IDE, shell, terminal
5. **Experience** — years, primary domain depth
6. **Code style** — indentation, quotes, semicolons, line length, naming
7. **Preferences** — architecture patterns, test framework, CI, cloud,
   database

Always offer "Other" / free-text. The profile should reflect the user,
not the question taxonomy.

### Subsequent runs: read and apply

Load the file, use its contents to shape the response. Examples:

- Generating a new project: pick defaults from the user's primary stack
- Reviewing code: apply their style preferences (semicolons, quotes)
- Recommending tooling: match their experience level (don't push CDK on
  someone who hasn't done IaC)
- Explaining concepts: calibrate depth to their stated experience

### Updates

When the user says "add X" or "I'm switching to Y":

1. Read the current profile
2. Identify the affected section
3. Update only that section
4. Save

Don't rewrite the whole file when one line changes.

## File Format

```markdown
# Developer Profile

## Basic Info
- **Name**: [name or handle]
- **Role**: [role]
- **Experience**: [years or level]

## Languages
### Primary
- [language 1]
- [language 2]

### Secondary
- [language 3]

## Frameworks & Libraries
### Backend
- [framework]

### Frontend
- [framework]

### Other
- [library list]

## Environment
- **OS**: [os]
- **Editor**: [editor]
- **Shell**: [shell]

## Code Style
- **Indentation**: [tabs/spaces + size]
- **Quotes**: [single/double]
- **Semicolons**: [JS/TS preference]
- **Line Length**: [max]
- **Naming**: [convention]

## Preferences
### Architecture
- [pattern]

### Testing
- [framework]

### DevOps
- **CI/CD**: [tool]
- **Cloud**: [platform]
- **Container**: [docker/k8s/etc]

### Database
- **SQL**: [preference]
- **NoSQL**: [preference]

## Notes
[free text]
```

## File Location

```
~/.agents/WHOAMI.md
```

The skill creates `~/.agents/` if it's missing.

## What NOT to Put Here

- Email, passwords, API keys — this is a profile, not a secrets file
- Project-specific facts — those belong in CLAUDE.md per project, not in
  the global profile
- Anything that changes more often than every few months — preferences
  drift slowly; if you're updating weekly, you're tracking the wrong thing

## Integration

Other skills can read this profile when they need it:

- A commit-message skill can pick up the user's preferred message style
- A planning skill can adjust scope and depth to experience level
- A scaffolding skill can pick defaults from the primary stack

The contract is one-way: skills read the profile, the profile doesn't
react to skills.
