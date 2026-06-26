---
name: {project-or-topic-slug}
description: One-line summary. What this note covers, not what the project is.
metadata:
  type: project
---

{Lead with the fact or decision, not the context. What is true right now,
what was decided, what's blocking. Future-you reading this in 3 months
should be able to act from the first sentence.}

**Why:** {The motivation — often a constraint, deadline, or stakeholder ask.
Project notes decay fast, so the why is what lets future-you judge whether
this is still load-bearing or stale.}

**How to apply:** {How this should shape suggestions or decisions. When it
fires, when it doesn't.}

## Status
- {Current state, dated. Use absolute dates (2026-06-26), not relative
  (yesterday, last week) — relative dates rot the moment you reread.}
- {What's done, what's open, who owns what.}

## Open items
- {Each item with owner + ETA + dependency if relevant.}

## Notes / decisions
- {Anything that would be expensive to re-derive — design choices, rejected
  options with the reason for rejection, surprises encountered.}

<!--
When to update vs archive:
- Update: as long as the project is active.
- Archive: when the work is done. Mark with ✅ + close date in the
  description. Don't delete — closed-but-archived context is what makes the
  next similar project cheaper.
- Don't preemptively close. A note that says "PR merged, deployed, verified"
  is more useful than one that says "done" without trail.

Linking:
- Issues, PRs, runbooks → just paste the URL or reference (e.g. #NNN, PR #NNN).
- Other memory notes → [[other-note-slug]] wiki-style.
- People → use the handle/name as it appears in your team.md or equivalent.
-->
