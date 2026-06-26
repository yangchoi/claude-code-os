# claude-code-os

> An opinionated, memory-driven operating layer for Claude Code.
> Not a skill library — a template for one that compounds.

Most Claude Code skill packs ship a list of static skills. After a few weeks
the list stops growing, the skills stop matching how you actually work, and
you're back to writing prompts from scratch every session.

This repo takes the opposite approach. The skills here are useful, but they
are not the product. The product is **the system that lets you keep
producing skills, feedback rules, and project context that compound over
months of real use** — without RAG, without a database, without leaving
plain markdown.

## What's in here

```
templates/    The system. Empty MEMORY.md skeleton, feedback-note format,
              project-note format. Copy these into your Claude Code memory
              directory and start writing.
docs/         How the memory system works, in detail. Start with
              docs/memory-system.md.
scripts/      memory-health-check.sh — catches the silent failure modes
              (size cap, broken wiki-links, missing frontmatter). Run weekly.
skills/       Thirteen skills that have earned their keep across months of
              real use. Each one decouples from any specific project.
docs/lessons.md   Six months in: what survived, what got deleted, what
                  surprised me.
```

## The system, in one paragraph

A single auto-loaded index (`MEMORY.md`, hard-capped at 200 lines) points to
topic files organized by type — `user`, `feedback`, `project`, `reference`.
The load-bearing piece is the `feedback` note: every correction the user
makes, plus every non-obvious approach they validate, gets one. Each note
leads with the rule, then *why* (the reason that lets future-you judge edge
cases), then *how to apply* (which keeps the rule scoped). Cross-references
between notes use `[[wiki-link]]` syntax. A health check script catches the
silent failure modes (index over 200 lines → entries truncated;
`[[link]]` to a missing note → unsurfaced TODO; note without frontmatter →
type-based behaviors won't fire). The first month feels like overhead. The
third month feels like leverage.

The full explanation is in [docs/memory-system.md](docs/memory-system.md).
The six-month retrospective is in [docs/lessons.md](docs/lessons.md).

## The skills

The thirteen below are the ones that survived the cull. Each one is
decoupled from any specific employer, project, or codebase — they work
the same way in a personal repo, a startup, or a large team setup.

| Skill | What it does |
|---|---|
| [safe-autonomy](skills/safe-autonomy/SKILL.md) | Autonomous on the inside (read/edit/test freely), gated at the boundary (commits, deploys, external APIs). Encodes the `[code]` / `[prod]` / `[irreversible]` taxonomy. |
| [agent-tune](skills/agent-tune/SKILL.md) | Reads Claude Code session logs, surfaces low-performing agents, proposes prompt edits with backup + rollback. The closest thing to an observability loop for your custom agents. |
| [parallel](skills/parallel/SKILL.md) | Fan out independent work to concurrent subagents. Single-message multi-Task pattern, optional tmux pane layout for visualization. |
| [workflow-guide](skills/workflow-guide/SKILL.md) | Reference for the Claude Code patterns that earn their keep: Plan Mode, interview-driven specs, parallel session sequencing, context management, headless mode. |
| [git-commit-pr](skills/git-commit-pr/SKILL.md) | Commit + PR flow with a pre-commit secrets check (file patterns + content patterns) and Conventional Commits style. |
| [deploy-watch](skills/deploy-watch/SKILL.md) | Background poll for Vercel deploys (via GitHub Deployments API) or AWS ECS rollouts, with desktop notification on completion or failure. |
| [switch](skills/switch/SKILL.md) | Project teleport with arrival context (branch, modified files, top of CLAUDE.md). Map of named projects in a JSON config. |
| [memo](skills/memo/SKILL.md) | Lightweight cross-session handoff notes stored in a single JSON file. For parallel sessions, not a knowledge base. |
| [my-config](skills/my-config/SKILL.md) | One-screen summary of what's actually loaded — settings, skills, agents, hooks, MCP servers. For "is X live?" debugging. |
| [whoami](skills/whoami/SKILL.md) | Persistent developer profile (stack, preferences, experience) so Claude doesn't re-ask the same setup questions every session. |
| [mybacklog](skills/mybacklog/SKILL.md) | Markdown-backed personal TODO list. add / done / remove. The file is plain enough that you can also edit it by hand. |
| [weekly-report](skills/weekly-report/SKILL.md) | Status report drafted from your real PRs, issues, and commits across a configurable repo set. Groups related changes into features and incidents. |
| [linkedin-draft](skills/linkedin-draft/SKILL.md) | Weekly post drafter that pulls from real shipped work, enforces a no-confidential-info filter and a no-emoji / no-rage-bait tone. Always gated before publish. |

## Why the system matters more than the skills

A skill is a frozen answer. A memory system is what lets the answer evolve.

When the user corrects you mid-session — "no, don't auto-commit", "stop
suggesting we batch this" — without a memory system, that correction
lives only in the current conversation. Next session, you re-make the
same mistake, the user re-corrects, and nothing accumulates. With this
system, each correction becomes a `feedback` note. By month three, the
default behavior matches how the user actually wants things done. By
month six, you can pick up any project and Claude knows the conventions
before you say them.

The skills are downstream of the system. They demonstrate what the system
produces, and they're useful in their own right — but if you only copy
the skills and skip the templates and the discipline, you'll end up with
a skill library that doesn't compound. Like the other ones.

## Quick start

If you want the full setup:

```bash
git clone https://github.com/yangchoi/claude-code-os
cd claude-code-os

# Copy the memory system templates into your Claude Code project memory dir
# (path varies by project; common locations below)
PROJECT_MEMORY="$HOME/.claude/projects/$(pwd | sed 's|/|-|g')/memory"
mkdir -p "$PROJECT_MEMORY"
cp templates/MEMORY.md "$PROJECT_MEMORY/"

# Install the health check
mkdir -p "$HOME/bin"
cp scripts/memory-health-check.sh "$HOME/bin/"
chmod +x "$HOME/bin/memory-health-check.sh"

# Install the skills you want, one at a time. Skills are independent.
cp -r skills/safe-autonomy "$HOME/.claude/skills/"
cp -r skills/parallel "$HOME/.claude/skills/"
# ... etc
```

The skills are independent. Install only what you'll use; the rest stays
in the repo.

If you want just one piece — say, the `safe-autonomy` skill or the
`memory-health-check.sh` script — they work standalone. The system
becomes more valuable as you adopt more of it, but there's no
all-or-nothing requirement.

## What this is not

- **Not a generic best-practice library.** Other repos already do that;
  this one is opinionated about the *meta-layer* of how to keep your
  agent setup honest over time, not about how to write a unit test.
- **Not a productivity system.** It doesn't track tasks, it tracks
  judgment — the kind that takes months to build and you don't want
  to lose to context window limits.
- **Not RAG.** No embeddings, no vector search. The corpus is bounded
  by what one person writes; auto-load + 200-line cap is enough.
- **Not finished.** The system is alive. The skills change as the work
  changes. Treat this as a snapshot of a working setup, not a frozen
  pattern.

## Where this fits

Plenty of skill packs already exist for the *what to do* layer — how to
write a spec, how to do TDD, how to review. This pack is mostly the
*how to remember what you decided* layer underneath that. They compose
well; use this for the operating system, the others for the canonical
engineering disciplines.

## License

MIT. Use, fork, adapt, ship.
