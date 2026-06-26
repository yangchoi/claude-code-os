---
name: workflow-guide
description: Reference for the Claude Code workflow patterns that earn their keep — Plan Mode, interview-driven specs, parallel sessions, context management, headless mode. Use when you want to know which pattern fits the current shape of work, or when the user asks how to use Claude Code effectively for X.
---

# Workflow Guide

The patterns below are the ones worth knowing. They're listed by the
problem they solve, not by feature name.

## "I'm about to do a non-trivial change"

Use **Plan Mode**. Three steps:

1. **Explore** — read related files, understand existing patterns
   ```
   read /src/auth and understand how we handle sessions
   ```

2. **Plan** — turn the work into a concrete list of changes
   ```
   What files need to change? Create a step-by-step plan.
   ```

3. **Implement** — execute the plan, run tests, fix failures
   ```
   implement the plan. run tests and fix failures.
   ```

Plan Mode is overhead for one-line fixes. Use it when the change touches
multiple files, when the right approach isn't obvious, or when there's a
decision to lock in before writing code.

## "I have a vague feature in mind"

Let Claude interview you instead of guessing:

```
I want to build [rough description]. Interview me using AskUserQuestion.

Cover:
- Technical implementation choices
- UI/UX requirements
- Edge cases
- Tradeoffs

Keep interviewing until we've covered everything, then write a spec.
```

The interview pattern catches the gap between what you asked for and what
you actually want before any code exists. Once the spec is written, drop
into Plan Mode.

## "I need to run multiple lines of work in parallel"

Pattern by level of parallelism:

### Level 1: Name your sessions

When you start a session, name it immediately:
```
/rename auth-rewrite
/rename rate-limit-fix
```

`claude --resume` shows named sessions in the picker so future-you can find
the right one. Unnamed sessions blur together.

### Level 2: Sequence dependent work across sessions

**Backend → Frontend pattern** (API exists first):
```
Session A (backend):  Build endpoint
                      ↓ "done: POST /api/foo, returns {id, name}"
Session B (frontend): Wire up against the now-real API
```

**Frontend → Backend pattern** (UI drives the contract):
```
Session A (frontend): Mock UI, declare what the API needs to look like
                      ↓ "need: GET /api/items?status=active"
Session B (backend):  Implement against the declared contract
```

### Level 3: Specialize sessions by role

Writer / Reviewer separation:
```
Session A (writer):   Implement rate limiter
Session B (reviewer): Review the rate limiter in @src/middleware/rateLimiter.ts
Session A:            Address this feedback: [paste session B output]
```

### Level 4: Project-scoped sessions

For large multi-project days:
```
Session 1: Project Alpha (all stack)
Session 2: Project Beta (all stack)
Session 3: Infra / shared tooling
Session 4: Reviews / hotfixes
```

For the parallel split mechanics, see the `parallel` skill.

## "Should I use a subagent?"

Use a subagent when:

- The work is naturally bounded and self-contained
- The output would otherwise pollute your main context with too much detail
- You want a specialist perspective (code review, security audit, test
  writing)

Examples:
```
use subagent code-reviewer to review this code
use subagent to investigate how authentication works in this codebase
```

Don't use a subagent when you'll need to iterate on the output across
multiple turns. Subagents have no memory of your conversation.

## "My context is getting full"

Three moves, by situation:

| Situation | Move |
|-----------|------|
| Starting genuinely unrelated work | `/clear` |
| Same problem failed 2+ times | `/clear`, restart with what you learned |
| Long session, want to keep going | `/compact` with explicit preserve list |

`/compact` accepts a "what to preserve" hint:
```
When compacting, preserve:
- The list of files I've modified
- The exact failing test name and error message
- The DB env I'm pointed at
- The branch I'm on
```

Without that hint, the compaction summary may drop the load-bearing facts.

## "I need to resume yesterday's work"

```bash
claude --continue    # Pick up the most recent session
claude --resume      # Choose from a list of recent sessions
```

Named sessions (`/rename`) make the resume picker scannable.

## "I want to script this"

Headless mode for one-off queries or batch work:

```bash
# Single query
claude -p "explain what this script does"

# Structured output for parsing
claude -p "list all API endpoints" --output-format json

# Streaming for live log processing
claude -p "analyze this log file" --output-format stream-json

# Batch migration with restricted tool access
for file in $(cat files.txt); do
  claude -p "migrate $file from React to Vue" --allowedTools "Edit,Bash(git commit:*)"
done
```

Headless mode is not interactive — there's no AskUserQuestion, no Plan
Mode, no permission prompts. Restrict `--allowedTools` to the minimum the
task needs.

## Pre-flight checks

### Before changing data

1. Read the current state
2. Verify the authoritative source (which DB / which collection / which API)
3. Identify the blast radius
4. Decide whether you need a backup

### Before changing code

1. Look for similar patterns in this codebase first
2. Verify there's a way to test the change locally
3. Run the local test command before pushing
