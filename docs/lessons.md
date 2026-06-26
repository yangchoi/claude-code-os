# Six months in: lessons from running a memory-driven Claude Code system

I started writing this system because I kept correcting Claude on the same
five things, week after week.

"Don't auto-commit without asking."
"Don't add AI signature lines to commits."
"Don't suggest I rest."
"Don't pull career framing into a technical question."
"Don't trust the merged-PR ancestry check on this repo — it squashes."

Every one of those was a correction I'd made before. Sometimes ten times.
Each session was a clean slate, and the corrections didn't stick. I'd watch
myself type the same words I typed last Tuesday and feel like I was running
the wrong loop.

So I built the loop I wanted. This is what I learned.

## The shape of the problem

Most agent setups optimize for the *current* turn. The user says something,
the agent reads the project's CLAUDE.md, decides what to do, does it. If
the user corrects the agent, the correction lives in the conversation, gets
applied for the rest of the session, and dies when the session closes.

That works fine for one-off tasks. It breaks for long-running collaboration
because the *judgment* the agent needs — what to do when X happens, why
this codebase squashes its merges, what the user means by "ship it" in this
project versus that one — has to be re-derived every session.

Skill libraries are the conventional fix. Ship a list of best-practice
prompts; let the agent pick one when the situation matches. They handle
the canonical engineering practices well — TDD, code review, security
audits. But they can't encode *my* corrections. They don't know that on
Tuesday I yelled "stop suggesting we rest" or that on Thursday I learned
the hard way that one of our repos uses squash merges and the
merged-base check gives the wrong answer.

That's the gap. Skill libraries answer "how should this be done in
general?" The thing I needed was "how should this be done *the way I want
it done*, given everything I've already taught you?"

## The system, finally written down

The structure ended up smaller than I expected. Four pieces:

1. A single index file (`MEMORY.md`) that Claude auto-loads at session
   start. Hard-capped at 200 lines because Claude truncates past that
   with no warning. Each line is a pointer, not a memory.

2. Topic files, organized by type: `user` (who I am), `feedback`
   (corrections + validated approaches), `project` (in-flight work),
   `reference` (where to find things outside this directory). Type is
   declared in frontmatter and shapes how the file is used.

3. `[[wiki-link]]` cross-references between notes. Lets related ideas
   stay coherent without duplication, and lets the network grow without
   anyone having to plan it.

4. A health-check script that catches the silent failure modes. Index
   over 200 lines? Lines over 200 characters? Missing frontmatter?
   Wiki-links to non-existent notes? It catches them; it does not fix
   them.

The structure is small on purpose. The leverage is in the discipline of
*writing the notes*, not in the schema.

## The feedback note is the load-bearing piece

I learned this one slowly. The first iteration of the system only saved
corrections — "do not do X". Three months in I noticed that Claude had
started over-correcting. Where I'd previously approved an approach
("yes, the single bundled PR was right here, splitting would've been
churn"), the next session it would propose splitting again because that
agreement was nowhere in writing.

The fix was simple: save *both directions*. Every feedback note now lives
in this shape:

```
{The rule, in one sentence.}

**Why:** {The reason — usually a past incident or a strong preference.}

**How to apply:** {When this fires, what changes, what's out of scope.}
```

Three things matter about this shape, and I had to learn each one by
getting the system wrong first.

**Lead with the rule.** Future-me reading this skim-first should be able
to apply the rule from the first sentence. If I wrote the reasoning first
and the rule at the bottom, the reasoning would get loaded and the rule
would be missed.

**The reason is load-bearing.** A rule without a reason is dogma. The
reason is what lets Claude (or future-me) judge edge cases. The rule
"don't auto-commit" plus the reason "because last quarter a `git add -A`
swept a `.env` file into history and we burned three hours rotating
keys" is a different rule than "don't auto-commit because I said so."
The first one knows when to bend; the second only knows how to fire.

**How-to-apply prevents over-firing.** Without explicit scope, rules
generalize. "Don't auto-commit" becomes "don't commit anything ever",
which is wrong. The how-to-apply line says *when* the rule fires and
when it doesn't. Most of my early feedback notes were missing this and
I kept having to add it after the fact when Claude over-applied them.

## What's worked

After six months of pruning, the system has settled into a few patterns
that earned their keep.

**Two-direction feedback.** As above. The day I started saving validated
approaches alongside corrections, the system stopped over-correcting.
Now there are maybe 80 feedback notes total. Roughly two-thirds
corrections, one-third "this was the right call" approvals. The split
matters; without the approvals, the system drifts conservative over
time.

**The 200-line cap.** I hate that it's necessary, but it's the most
useful constraint in the system. Without it, the index becomes a dumping
ground. With it, every new entry forces me to ask "is this important
enough to push something else out?" Most days the answer is no, which
is the right answer. The cap is a feature, not a bug.

**`[[wiki-link]]` cross-refs.** I expected to use these maybe twice a
week. I use them constantly. They let one rule reference another without
restating it, which keeps individual files focused. They also let me
write half-formed thoughts — `[[some-future-rule]]` — that later become
real notes. The health check flags the unresolved ones every week and
I either write the note or remove the link.

**Hard rules at the top.** There's a small section of "absolute rules"
that load first. Right now it has maybe seven entries — things like "no
AI signature lines in any commit", "no autonomous commits without
explicit OK", "treat read tools as auto-allowed but mutations stay
gated". They're load-bearing enough that they belong above everything
else. Keeping the section small is the discipline; if it ever grows past
ten I'll need to merge or demote.

**Absolute dates everywhere.** Early on I'd write "last Thursday" or
"yesterday" in notes. Three weeks later I'd reread and have no idea
what date that referenced. Now every date is absolute (`2026-06-26`).
It's slightly more typing; it pays off the third time I read the note.

**Closed-but-archived notes.** When a project finishes, I don't delete
its notes. I mark them with the close date and leave them. Six months
of closed notes turn out to be the cheapest training data for "how
should I handle this kind of project next time?" The alternative —
deleting — feels cleaner but loses context that took weeks to build.

## What got cut

Some patterns I tried didn't survive. Worth saying so.

**Thematic indexing.** First version of the index grouped feedback by
theme — "communication", "git", "testing", "deployment". Sounded clean.
In practice I could never remember which theme a rule belonged to and
ended up grepping the index instead of using it. The current index is
organized by importance (hard rules at top), then by domain (per
project), then by behavior (feedback by topic cluster). Importance-first
beat theme-first by a wide margin.

**Auto-summarization.** I tried scripts that compress old notes into
shorter ones. It corrupted the reasoning every time. The compressed
version lost the *why*, which is the part I most needed. Now I rewrite
by hand when a note gets too long, and I keep the original commit in
git history.

**Tagging.** Tried YAML `tags: [foo, bar]`. Used them maybe three times.
Then never again. Wiki-style links do the same job better because the
links are bidirectional — a tag tells you "this note is about X"; a link
tells you "this note relates to that specific other note." The
specificity is what makes it useful.

**Daily prompts.** Tried adding "what did you ship today" to a daily
prompt. It became filler. Removed. The system records *judgment*, not
activity; the moment it tried to become a journal, the noise drowned
out the signal.

**Career and personal context loading by default.** I had a section
that loaded my career/portfolio/study trajectory into every session. It
started bleeding into unrelated answers — I'd ask a technical question
and get an answer that gently framed it against my goals for the year.
Removed and replaced with an explicit "stay in the question's lane"
rule. Cross-domain context now loads only when I name the cross-domain
explicitly.

## Surprises

**Three weeks was the inflection point.** The first two weeks felt like
pure overhead. Writing a feedback note for every correction is
ceremony, and it doesn't feel like leverage until enough notes
accumulate that Claude starts behaving differently *before* you
correct it. That inflection happened around three weeks in. After that
the ratio of "writing memory" to "benefiting from memory" inverted
sharply.

**The health check fired more than I expected.** I built
`memory-health-check.sh` thinking I'd run it monthly, find nothing,
feel reassured. In practice it fires every week or two. Usually it's
the index creeping over 200 lines or a link to a note I never wrote.
The script is what keeps the discipline honest.

**Hand-editing happens.** I expected to drive the system through
Claude. In practice I edit `MEMORY.md` and the feedback notes by hand
constantly. Renaming, merging, demoting from index to topic file.
Plain markdown is the right format because both Claude *and* I can
edit it, and we trade off who edits without friction.

**Corrections compound, validations don't.** Adding a correction
("don't do X") changes behavior immediately and obviously. Adding a
validation ("yes, X was right") changes behavior subtly — Claude
suggests less alternative paths, hedges less. I almost stopped
writing validations because they didn't *feel* like they were doing
anything. The day I noticed the system had started over-correcting
without them, I started writing them again.

**The meta-skills emerged late.** Tools like `agent-tune` and the
`safe-autonomy` skill — the things that observe and shape the system
itself — only made sense once the rest had been running for a few
months. Trying to build them earlier would have been premature. The
system has to exist before its meta-layer is meaningful.

**The system was harder to keep small than to keep useful.** Useful
came naturally — every correction was a candidate note. Small was the
real discipline. Pruning, merging, demoting from index to topic, asking
"is this still load-bearing?" every few weeks. Most of the maintenance
effort goes into staying compact, not into adding.

## How to start

If you want to try this:

1. Copy `templates/MEMORY.md` into your Claude Code project memory
   directory. The path varies by project — usually
   `~/.claude/projects/<slug>/memory/MEMORY.md`.

2. Add two or three hard rules at the top. Pick corrections you've
   already made more than once. Those are the ones that hurt the most
   when they're missing.

3. Install `scripts/memory-health-check.sh` somewhere on your `$PATH`
   and run it weekly. Treat it like a test suite.

4. Then just write. Every correction becomes a feedback note. Every
   project decision worth remembering becomes a project note. Don't
   batch this — write the note in the same session you had the
   correction, while you still remember the reason.

5. After three weeks, evaluate. If it hasn't started feeling like
   leverage, the notes are probably too vague. Sharpen the rules; add
   the *why* and the *how to apply* lines if they're missing.

That's the whole onboarding. The rest is months of accumulating.

## What I'd build next

The natural next layer is observability for the memory system itself.
Right now I have visibility into how custom agents perform (`agent-tune`
reads the session logs and surfaces low-performers). I don't have the
same loop for feedback notes — which rules fire often, which fire never,
which contradict each other in subtle ways. I'd want a script that
parses sessions and reports per-rule statistics so I can prune the dead
ones with the same discipline I prune dead agents.

Beyond that, I'd want better tooling for *forgetting*. The system is
good at remembering and bad at letting go. Some feedback was right at
the time and is wrong now. Some project context was load-bearing for
three months and is dead weight in month four. The deletion path
exists but it's manual, and I rely on the weekly health check to
remind me. A reaper that flags stale notes by their last-referenced
date would help.

I'd also want a portable version. The system as written is bound to
Claude Code's auto-load conventions. The same discipline works in any
agent setup that lets you inject a small index — Cursor, Aider,
agent SDK builds, anything where you can prepend a few hundred lines
of context per session. Generalizing the templates so they work in
those contexts is mostly a packaging problem, but it's worth doing.

## Closing

The system isn't elegant. It's a folder of markdown files with a
strict naming convention and a script that yells at you when you
break the rules. There's no UI, no embeddings, no search beyond
`grep`. The leverage comes from the discipline of writing things
down in a specific shape, then trusting the auto-load to surface
them at the right moment.

Six months in, I can pick up any project, in any of the languages
I work in, and Claude knows my conventions before I say them. The
common corrections don't happen. The validated approaches stick.
When something does need a correction, it's almost always something
new — and the correction becomes a new note, and the system gets
slightly more accurate again.

That compounding is what I wanted from an agent setup the first day
I started writing it. It took building this to actually get it.
