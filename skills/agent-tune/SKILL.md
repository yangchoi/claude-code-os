---
name: agent-tune
description: Analyzes agent and skill usage logs to surface low-performing prompts, then proposes and applies edits with version history. Use when you suspect an agent is underperforming, when you want to know which custom agents are silently failing, or when you want a feedback loop between actual usage and prompt quality.
---

# agent-tune

A self-tuning loop for your custom Claude Code agents and skills.

## Overview

Custom agents and skills accumulate. After a few months you have dozens —
some firing well, some never firing, some firing but consistently failing
in ways you don't notice until you go looking. This skill closes the loop:
read the execution logs Claude Code already writes, find the agents and
skills that are underperforming, propose targeted prompt edits, and apply
them with backup + rollback.

It's not magic. It's a heuristic pipeline that does the work of reading
hundreds of session logs so you don't have to.

## When to Use

- "Which of my agents are actually getting used?"
- "Why does my code-reviewer keep missing X?"
- "Tune my agents."
- "Find low-performing prompts."

Skip when you have only a handful of agents and you already know how
each one is doing.

## What It Does

| Subcommand | What it does |
|------------|--------------|
| `report` | Per-agent success rate, call count, error patterns, time spent |
| `suggest <agent>` | Propose specific edits to a named agent's prompt |
| `suggest --auto` | Detect low-performers automatically and suggest edits |
| `apply <agent>` | Back up the current prompt, apply the suggested edit |
| `history <agent>` | Show version history for a specific agent |
| `rollback <agent>` | Restore the previous version |

## Options

| Option | Default | Meaning |
|--------|---------|---------|
| `--days N` | 7 | Analyze the last N days of session data |
| `--threshold N` | 80 | Success-rate threshold (%) below which an agent is flagged |
| `--min-calls N` | 3 | Skip agents with fewer than N calls in the window |

## How the Pipeline Works

1. **Parse** the session logs Claude Code writes to disk
   (`~/.claude/projects/*/stream.jsonl` and per-session JSONL files).
2. **Aggregate** per-agent and per-skill: call count, completion rate,
   common error signatures, average time-to-completion.
3. **Detect** outliers — agents below the success threshold with enough
   call volume to be meaningful.
4. **Suggest** prompt edits based on the error patterns. The suggestions
   are heuristic, not generated from a model loop — they pattern-match
   against known failure modes (ambiguous trigger conditions, missing
   exit criteria, no rationale-rebuttal tables, etc.).
5. **Apply** the edit, but back up the previous version first to a
   timestamped file in `.versions/` so rollback is one command.

## Version Management

Each apply creates a backup at `<agents-dir>/.versions/{agent}.{date}.md`
and appends a one-line entry to `.versions/.changelog.md`. The history
subcommand reads this log; rollback walks back one version.

## Dependencies

Standard library only. No additional installs.

## Configuration

Set `AGENTS_DIR` in your environment if your agents live somewhere other
than the default `~/.claude/agents/` (some users keep agents inside a
project repo). The script will use that directory for both reading
prompts to tune and writing backups.

## Limitations

- The heuristic suggestions are intentionally conservative. They won't
  rewrite an agent from scratch; they'll add missing scaffolding
  (trigger conditions, exit criteria, anti-rationalization tables).
- Detection is correlation, not causation. An agent with low success rate
  might be working on inherently hard tasks. Always read the suggested
  edit before applying.
- Requires Claude Code session logs to exist. Fresh setups with no usage
  history have nothing to analyze.
