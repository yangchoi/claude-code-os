---
name: feedback-{short-kebab-slug}
description: One-line summary used to decide relevance in future conversations. Be specific — vague descriptions get loaded but don't fire.
metadata:
  type: feedback
---

{The rule itself, stated in one or two sentences. Lead with the rule, not the
backstory. A reader who has never seen this before should be able to apply it
from the first paragraph alone.}

**Why:** {The reason the user gave. Often a past incident, sometimes a strong
preference. Knowing *why* lets future-you judge edge cases instead of blindly
following the rule. If the rule came from a bug or an outage, link to the
incident so the context survives.}

**How to apply:**
- {When this rule kicks in — which kinds of work, which signals trigger it.}
- {The actual behavior change — what to do, what to stop doing.}
- {Optional: what's NOT covered. Where the rule does not apply. This is what
  prevents the rule from over-firing into adjacent situations.}
- {Optional: links to related feedback with [[other-feedback-slug]] — wiki-style
  cross-references that let the network of rules stay coherent. A link to a
  rule that doesn't exist yet is fine; it marks something worth writing later.}

<!--
Notes on writing feedback that compounds:

1. Save corrections AND validated approaches. If you only save corrections,
   you'll avoid past mistakes but drift away from non-obvious approaches that
   already worked. Both directions matter.

2. The reason is the load-bearing part. A rule without a reason is dogma —
   future-you (or future-Claude) can't reason about whether it still applies
   when the situation has shifted slightly.

3. If you find yourself writing a third paragraph, the entry is becoming a
   topic, not a rule. Split it: keep the rule here, move the deep context to
   a separate file and link with [[name]].

4. Update or delete feedback when it turns out to be wrong. The system only
   works if it stays honest. Stale rules pollute every future session.
-->
