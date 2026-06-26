---
name: safe-autonomy
description: Lets Claude run autonomously on implementation while keeping irreversible and externally-visible steps gated. Use whenever you want autonomous execution on the inside but explicit approval at the boundary — commits, merges, deploys, external messages, third-party API mutations, and shared-resource changes.
---

# Safe Autonomy

## Overview

Most agent workflows trade off in the wrong place: either every step needs
approval (slow, exhausting), or nothing does (fast, occasionally catastrophic).
Neither matches how senior engineers actually work — they push hard through
implementation, then stop hard at the boundary before anything irreversible
happens.

This skill encodes that pattern. Inside the local working tree, run
autonomously: read, write, edit, refactor, run tests, iterate until done.
At the boundary — git history, external services, shared infrastructure,
human-visible artifacts — stop and confirm before crossing.

## When to Use

Apply this skill on any non-trivial task where the user has said something
like "just do it", "go ahead", "implement it", or has accepted a plan and
wants the work done. Do NOT use it for one-shot mechanical operations where
explicit step-by-step approval is the right shape.

## The Two Modes

**Inside mode (autonomous):**
- Read any file in the project. Use Glob, Grep, and Read freely.
- Edit, write, and delete files in the working tree.
- Run tests, builds, linters, type checks, formatters.
- Iterate on failures until the work meets the bar.
- No per-step approval needed — the implementation runs end-to-end.

**Boundary mode (gated):**
- Anything that touches git history beyond the working tree.
- Anything that calls an external service in a way that creates persistent
  state visible to others.
- Anything that cannot be cleanly undone in <30 seconds by a different process.

When the next step is in boundary mode, stop. Show what's about to happen,
why, and the exact command. Get explicit confirmation. Then execute.

## The Boundary Taxonomy

Three labels tell the user *and* future Claude which category they're in:

### `[code]` — local, reversible
Editing files in the working tree. Reverting is `git checkout`. No external
state has changed. Run freely without label most of the time; use it only
when calling out work that touched something subtle (config, schema,
generated files) and the user should know.

### `[prod]` — touches production state
Production database writes, production deploy triggers, production config
changes, production cache invalidation, anything that affects a running
service real users are talking to. Always labeled. Always gated.

### `[irreversible]` — cannot be undone, or undone cleanly
Force pushes, branch deletes, repo deletes, `git reset --hard`, dropping
database tables, deleting cloud resources, publishing immutable artifacts
(npm publish, container image push to immutable tag), sending external
messages (Slack, email, GitHub PRs/issues/comments to other repos),
mutations through third-party SaaS write APIs where there's no undo
endpoint.

The labels are not interchangeable. `[prod]` can sometimes be rolled back;
`[irreversible]` cannot. A force push to main is both, and the more
restrictive label wins.

## The Gate Checklist

Before any `[prod]` or `[irreversible]` step:

1. **Name the artifact.** "About to push 4 commits to `origin/main`." Not
   "deploying" — be specific enough that the user can decide.
2. **Show the command.** Exact text that will run. No abbreviations,
   no `...` truncation.
3. **State the blast radius.** What changes for users, what's visible to
   the team, what gets logged where it can't be unlogged.
4. **Confirm undo path.** Can this be reverted? How fast, by whom? If
   there's no undo, say so plainly.
5. **Wait for explicit yes.** Not "sounds good", not silence, not
   "whatever you think". An actual confirmation that names what's being
   approved.

## Anti-patterns

- **Sneaking past the gate** with phrasing like "I'll just commit this and
  we can revert later." Commits are gated; later-revert is more work
  than now-confirm.
- **Bundling gated and ungated steps.** "I'll edit the file, run tests,
  and push the branch." The push is gated; ask for it separately.
- **Treating dev/staging as ungated.** Dev and staging environments
  often share resources with prod (shared database, shared message
  queue, shared third-party tenant). If the boundary effects can reach
  prod, it's `[prod]`.
- **Treating reads as gated.** Reading files, listing directories,
  grepping for symbols, running read-only API calls — these are inside
  mode. Asking for permission to read slows everything down without
  adding safety.
- **Pre-approval inflation.** "Can I commit this whole branch?" is not
  a pre-approval — it's a request to gate one specific commit. Each
  gated step needs its own confirmation.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's a small commit, it's fine" | Small commits are reversible by another `git revert`. The gate isn't about size, it's about who sees the change and when. |
| "The user said 'go ahead' earlier" | "Go ahead" applies to the implementation scope they had in front of them. New gated steps need their own confirmation. |
| "It would be faster to just push" | The slowness of asking is measured in seconds. The cost of an unwanted push is measured in revert PRs, rollback meetings, and trust. |
| "It's a private repo, no one will see it" | Private doesn't mean invisible — collaborators, CI, deploy hooks, and notification systems all see the push. |
| "I'll undo it if it's wrong" | "Undo" works on the working tree. Once external state has changed, undo becomes apology + cleanup. |
| "The user is busy, I'll batch the approvals" | Batched approvals collapse to "yes whatever" — that's not approval, that's exhaustion. One gate, one decision, one moment of attention. |

## Verification

After applying this skill on a task:

- [ ] Implementation ran autonomously without per-step approval requests
- [ ] No external state was changed without a labeled gate
- [ ] Every gated step named the artifact, showed the command, stated
      blast radius, and confirmed the undo path before execution
- [ ] No bundled "I'll do A and B and C" where B or C crossed a boundary
- [ ] Read tools (Read, Glob, Grep, read-only Bash) ran without permission
      prompts; only mutations were gated
