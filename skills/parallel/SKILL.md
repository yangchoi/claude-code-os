---
name: parallel
description: Splits independent work into concurrent subagents and runs them in parallel. Use when you have 3+ independent files to modify, a large refactor where the impact range exceeds 5 files, multi-service work that spans frontend and backend, or any task you'd otherwise crank through serially while wall-clock burns.
---

# Parallel

Concurrent subagent execution with optional tmux visualization.

## Overview

The Task tool runs one subagent at a time by default. When you have
genuinely independent pieces of work — three test files with disjoint
fixtures, frontend and backend that don't import each other, three
codebase regions to analyze — running them serially wastes wall-clock
time you don't need to spend.

This skill structures the parallel-fan-out pattern: split the work,
launch all subagents in a single message, monitor their output, merge
the results.

## When to Use

Trigger explicitly:
- `/parallel` — split the current task into parallel work
- `/parallel tmux` — launch a tmux session with one pane per agent
- `/parallel status` — check what's running

Auto-trigger criteria (Claude decides):
- 3+ independent files to modify
- 5+ skipped/failing tests to fix where each is independent
- Multi-component analysis (each component analyzable in isolation)
- Refactor with 5+ files in the impact range and no cross-file ordering
- Frontend + backend changes that don't share files

## The Pattern

### Step 1: Split

Analyze the work for independence:

```
1. Identify dependencies between pieces of work
2. Group dependent pieces into phases
3. Within each phase, identify independent units suitable for parallel
4. Verify: would running unit A before unit B change the outcome? If no, they're parallel-safe.
```

### Step 2: Launch all subagents in one message

The Task tool only runs concurrently if you call it multiple times **in
the same message**. Sequential calls (one per message) are serial.

```
Single message with three Task calls in parallel:
  Task A: { subagent_type: "Explore", prompt: "...", run_in_background: true }
  Task B: { subagent_type: "general-purpose", prompt: "...", run_in_background: true }
  Task C: { subagent_type: "code-reviewer", prompt: "...", run_in_background: true }
```

`run_in_background: true` is what makes the parent shell continue
without blocking. The completion notification arrives when each agent
finishes.

### Step 3: tmux visualization (optional)

If you want to see each agent's output in real time, run inside tmux
and use a four-pane layout:

```bash
tmux new-session -s parallel \; \
  split-window -h \; \
  split-window -v \; \
  select-pane -t 0 \; \
  split-window -v
```

```
┌─────────────────┬─────────────────┐
│  Main Claude    │  Agent A output │
│  (driver)       │  (tail -f)      │
├─────────────────┼─────────────────┤
│  Agent B output │  Agent C output │
│  (tail -f)      │  (tail -f)      │
└─────────────────┴─────────────────┘
```

### Step 4: Monitor and merge

```
1. Use TaskOutput to check each agent's result as it completes
2. Collect results in completion order
3. Merge into a single artifact (file, summary, PR, whatever the task produced)
```

## Examples

### Test fixing

```
Task: fix 10 skipped tests in the dialog component

Split:
- Agent A: dialog-basic.test.ts (3 tests)
- Agent B: dialog-advanced.test.ts (4 tests)
- Agent C: dialog-edge-cases.test.ts (3 tests)

All three Task calls in a single message with run_in_background: true.
```

### Cross-stack refactor

```
Task: rename a domain concept across frontend and backend

Phase 1 (parallel):
- Agent F: frontend rename (components, hooks, types)
- Agent B: backend rename (controllers, services, DTOs)

Phase 2 (serial, depends on phase 1):
- Integration check across the seam
```

### Multi-region exploration

```
Task: trace how feature X is implemented across the codebase

Three Explore agents in parallel, each scoped to a directory tree.
Merge their findings into one map.
```

## Auto-Trigger Heuristics

| Signal in user message | Decision |
|------------------------|----------|
| "every file", "all components" | Count files; 3+ → parallel |
| "fix the skipped tests" | Count skips; 5+ → parallel |
| "frontend and backend" | Disjoint scopes → parallel |
| "refactor", "migrate" | Impact range; 5+ files → parallel |
| "find", "analyze", "trace" | Spawn multiple Explore agents in parallel |

## Anti-Patterns

- **Sequential Task calls.** One Task call per message is serial regardless
  of `run_in_background`. The parallelism comes from a single message
  with multiple Task calls.
- **Parallel with shared files.** If agent A and agent B both edit
  `package.json`, you'll get a merge conflict at best, lost work at
  worst. Either serialize them or use git worktree isolation.
- **Over-splitting.** Splitting two-file work into two agents costs
  more in setup than it saves. Parallel earns its overhead at 3+.
- **Pretending dependent work is independent.** If A's output is B's
  input, that's a phase boundary, not a parallel split.

## Requirements

- Claude Code Task tool available
- tmux 3.0+ for the visualization variant (optional)

## Tips

- Independence is the bar. If you can't articulate why two pieces are
  independent, they probably aren't.
- Phases beat over-eager flattening. Two parallel phases of three agents
  each is cleaner than six agents with hidden ordering.
- For agents that mutate files, use worktree isolation (`isolation:
  "worktree"` on Task calls that support it).
- Check completed agents with TaskOutput; don't poll. You'll be notified
  when each finishes.
