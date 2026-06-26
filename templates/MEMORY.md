# Memory

<!--
This file is auto-loaded into every Claude Code session. Treat it as an index,
not a memory. Each entry is one line under ~150 chars. Detail goes in topic files.

Health rules (enforced by scripts/memory-health-check.sh):
- Stay under 200 lines total. Past 200, Claude Code truncates and you silently
  lose context. Move detail out before that point, do not let it bloat.
- One line per entry. If you need more, the entry is a topic, not an index line.
- `[Topic title](./topic-file.md) — one-line hook` is the canonical format.
- Sections are stable. Order by importance, not chronology.

Memory types (each file declares its type in frontmatter `metadata.type`):
- user      → who the user is; preferences; what they know
- feedback  → corrections + validated approaches; explicit "do/do not"
- project   → ongoing work; decisions; deadlines; people involved
- reference → pointers to external systems (Linear, dashboards, runbooks)
-->

## 🚨 Hard rules (override defaults; check before any non-trivial work)
<!--
The shortest list that protects you from your own worst defaults. Each rule is a
single line, links to a topic file with the full reasoning. Keep this section
small and load-bearing — if it grows past ~10 lines it stops being scannable.
-->
- _Add hard rules here. Examples: "no autonomous commits without explicit OK",
  "no AI signatures in any repo", "irreversible/external API calls require
  pre-approval", "treat read tools as auto-allowed; mutations stay gated"._

## User
<!--
Stable facts about you that shape how Claude should work with you. Role,
working style, technical background, communication preferences. Not a CV.
-->
- _Add user-facing context. Examples: working style, role, communication
  preferences, decision-making patterns._

## Projects
<!--
One section per project. Inside each section: overview, environments,
conventions, gotchas, in-flight issues. Issue-specific lines should link to
topic files and get archived (not deleted) when the issue closes.
-->
- _One section per project._

## Feedback — patterns you've corrected or validated
<!--
The thing that makes this system compound. Every time you say "no, not like
that" or "yes, that was the right call" — save it. Lead with the rule, then
**Why:** (the reason — often a past incident) and **How to apply:** (when this
kicks in). Linking related feedback with [[name]] keeps the network coherent.
-->
- _Add feedback entries here as they accumulate._

## References — external systems
<!--
Where information lives outside this directory. Linear projects, dashboards,
runbooks, internal wikis. One line per pointer with what it covers.
-->
- _Add external system pointers here._
