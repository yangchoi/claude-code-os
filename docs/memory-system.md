# The Memory System

This is the part that makes the rest compound.

A skill library teaches Claude how to do things. A memory system teaches Claude
how to do things *the way you want them done* — and keeps that knowledge alive
across sessions, projects, and months of changing context.

The system is four pieces, all of them small:

1. **`MEMORY.md`** — a one-page index, auto-loaded into every session.
2. **Topic files** — one file per piece of context, organized by type.
3. **Wiki-style cross-links** — `[[other-note]]` references that let related
   knowledge stay coherent without duplication.
4. **A health check** — a script that catches the failure modes that quietly
   break the system.

That's it. The leverage is in the discipline, not the structure.

## Why the index matters

Claude Code auto-loads `MEMORY.md` into every conversation. But it does so with
a silent cap: entries past line 200 are truncated. You don't get a warning. You
just notice, three weeks later, that a rule you wrote stopped firing.

So `MEMORY.md` is treated as an **index**, not a memory. Each line is a pointer
under ~150 characters. Detail lives in topic files. The index stays scannable
forever, even after 200 topic files have accumulated.

Example index line:

```
- [feedback_commit_safety.md](./feedback_commit_safety.md) — no autonomous commits without OK, no `git add -A`, no personal-file staging
```

That's enough for Claude to know the rule exists and decide whether to load
the full file. The full file is where the reasoning lives.

## The four memory types

Every topic file declares its type in frontmatter:

```yaml
---
name: feedback-commit-safety
description: One-line summary, used to decide relevance in future sessions.
metadata:
  type: feedback
---
```

| Type        | What it stores                                              | When to write                                                    |
| ----------- | ----------------------------------------------------------- | ---------------------------------------------------------------- |
| `user`      | Stable facts about you — role, preferences, working style   | Any time you learn something about yourself worth keeping        |
| `feedback`  | Corrections AND validated approaches                        | Every time the user says "no, not like that" OR "yes, that was right" |
| `project`   | In-flight work — decisions, deadlines, who owns what        | When you learn the *why* behind work, not the *what*             |
| `reference` | Pointers to external systems (Linear, dashboards, runbooks) | When you find something authoritative outside this directory      |

The types do real work. `feedback` notes are loaded as behavior modifiers.
`project` notes carry decision context. `reference` notes prevent re-deriving
"where does that live?" every time.

## The feedback note is the load-bearing piece

Most memory systems save corrections and call it done. That gives you a system
that's good at not repeating mistakes — and slowly drifts away from validated
approaches the user has already endorsed.

The fix is to save *both directions*. Every feedback note follows this shape:

```markdown
{The rule, in one sentence.}

**Why:** {The reason — usually a past incident or a strong preference.}

**How to apply:** {When this kicks in. What changes. What's out of scope.}
```

Three things matter about this shape:

1. **Rule first, reason second.** A reader (or Claude in a future session) can
   apply the rule from the first sentence alone. The reason is for edge cases.
2. **The reason is load-bearing.** A rule without a reason is dogma. Without
   *why*, you can't judge whether the rule still applies when the situation
   shifts slightly.
3. **How-to-apply prevents over-firing.** "Don't auto-commit" is a fine rule
   until Claude refuses to commit anything ever. The how-to-apply line is what
   keeps the rule scoped.

When you find yourself writing a fourth paragraph in a feedback note, you've
crossed from rule into topic. Split it: leave the rule in the feedback file,
move the deep context to its own note, link with `[[name]]`.

## Wiki-style cross-links

References between notes use double brackets:

```markdown
This rule complements [[feedback-autonomous-then-review]] — autonomous
implementation is the default, but this rule keeps the irreversible steps
gated.
```

A `[[link]]` to a note that doesn't exist yet is fine. It marks something
worth writing later, not a broken reference. The health check flags missing
links so you can decide: write the note, or remove the link.

The result is a graph, not a hierarchy. You can fold one feedback note out
into three smaller ones, or merge five project notes into a topic file,
without breaking the connective tissue.

## What goes in the index, what doesn't

This rule turns out to be the hardest part of the discipline.

**Index lines should be:**
- Hard rules that need to fire on every session
- Pointers to active project work, with a one-line status
- High-level "how I work" facts the model should know at session start

**Topic files should be:**
- The actual rule text + reasoning + scope
- Project state and decision logs
- Anything longer than one line of useful summary

A line that says "see file X for details" is a smell — it means the index is
trying to be the memory. Either compress to a one-line rule, or move the line
out of the index entirely.

## The 200-line cap is a feature, not a bug

The cap forces compression. Without it, the index becomes a dumping ground,
gets too long to scan, gets truncated mid-section, and entries silently stop
loading. The cap makes pruning a non-negotiable habit.

`scripts/memory-health-check.sh` enforces this:

```
$ scripts/memory-health-check.sh
❌ MEMORY.md is 212 lines (cap: 200). Entries past 200 are truncated.
   Move detail out of the index. Each line should be ≤ ~150 chars.
⚠️  Index lines over 200 chars (these belong in topic files):
   8: 306 chars: - 머지 전 리뷰 재확인: [feedback_check_reviews_before_merge.md]...
```

Run it weekly. When it fires, fix it immediately — every day past the warning
is a day where some rule isn't firing.

## How the system evolves

The compounding shape:

```
Session 1:
  user: "no, don't auto-commit without asking"
  → save feedback note `feedback-commit-safety`
  → add one-line entry to MEMORY.md

Session 17 (3 weeks later):
  Claude reads MEMORY.md at session start, sees the rule
  → behavior is correct from the first turn, no re-correction needed

Session 42 (2 months later):
  Edge case: "but for this one PR you can auto-commit, I'm leaving"
  → Claude can apply the rule and recognize the explicit override
  → because the **Why** explains the rule isn't dogma, it's a default

Session 67:
  Old rule turns out to be wrong (workflow changed)
  → update or delete the feedback note
  → MEMORY.md index line stays accurate
```

The system stays honest only if you update and delete. Stale rules pollute
every future session. Treat memory hygiene like code hygiene — refactor when
things shift, delete when things die.

## What this is NOT

- **Not a wiki.** Wikis are for shared reference docs. This is a single-user
  context layer for an agent.
- **Not a journal.** A journal records what happened. This records what should
  happen *next time*.
- **Not RAG.** No embeddings, no vector search. The index + auto-load model
  is enough when the corpus is bounded by what one person actually writes.
- **Not a productivity system.** It doesn't track tasks, it tracks *judgment*.

## Starting from scratch

If you're spinning up the system from zero:

1. Copy `templates/MEMORY.md` to your Claude Code project memory directory
   (usually `~/.claude/projects/<project-slug>/memory/MEMORY.md`).
2. Add 2-3 hard rules under the first section. Pick the corrections you've
   already made multiple times — those are the ones that hurt the most when
   they're missing.
3. Add `scripts/memory-health-check.sh` to your repo or a `~/bin/` location.
   Run it weekly.
4. Then just write. Every correction becomes a feedback note. Every project
   decision becomes a project note. The system grows itself.

The first month feels like overhead. The third month feels like leverage.

By month six you can pick up any project and Claude knows how you want it
done before you say it.
