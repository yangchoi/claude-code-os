---
name: linkedin-draft
description: Drafts a weekly LinkedIn post grounded in the actual work you shipped, with a strict tone guide and a no-confidential-info filter. Use when you want to write something honest about AI-assisted development without the rage-bait, hashtag-stuffed, generic LinkedIn voice.
---

# linkedin-draft

A weekly LinkedIn post writer that pulls from your real work and refuses
to sound like LinkedIn.

## Overview

Most engineer-on-LinkedIn posts read the same: emoji, hook, list of tools,
hashtags, fake urgency. This skill writes the opposite: a short, honest
piece based on something concrete you actually did this week.

It hooks into the same data the `weekly-report` skill uses (your PRs,
issues, commits), picks one insight worth sharing, drafts in plain
English, and refuses to publish anything until you've reviewed it.

## Usage

```
/linkedin-draft                  Collect this week's material, draft a post
/linkedin-draft collect          Surface 3 candidate topics, you pick
/linkedin-draft write <topic>    Draft directly from a topic you name
/linkedin-draft list             Show recent drafts
/linkedin-draft publish          Push the latest draft (requires explicit OK)
```

## Tone Guide (Strict)

The skill is opinionated about what makes a post worth reading. These
rules are non-negotiable:

**Required:**
- Honest. Only facts you can defend. No hyperbole.
- Specific. A concrete example, a real number, a real before/after.
- Useful. The reader should be able to do something with it — try a
  technique, copy a pattern, avoid a mistake.

**Forbidden:**
- Cynical or boastful tone
- Outrage hooks or rage-baiting opening lines
- Emoji
- Hashtag stuffing
- Generic motivational lines ("never stop learning")
- "Hot takes" without backing
- Confidential information about your company, customers, infrastructure

**Confidentiality rules:**
- Never name your employer, internal projects, internal services
- Never include cluster names, hostnames, database identifiers, customer
  names
- Replace identifiers with generic descriptions ("a Web3 platform",
  "an analytics dashboard", "my team's API")
- When in doubt, leave it out

## Post Structure

The default shape, 150-300 words in English:

1. **Opening (1–2 lines)** — an honest observation or moment
2. **Context (2–3 lines)** — what you actually did
3. **Concrete method (bulleted list)** — specific enough to copy
4. **Closing (1 line)** — plain, no flourish

## Process

### Step 1: Collect

Read this week's PR titles, commit messages, and closed issues (same
source as `weekly-report`). Extract 3 candidate angles, each with:

- A one-line summary of the underlying work
- The lesson or pattern it illustrates
- Why this is post-worthy (specificity, generality, or unexpectedness)

Use `AskUserQuestion` to let the user pick one.

### Step 2: Draft

Write the English post. Apply the tone guide and the post structure.

While drafting:
- Anything you'd be embarrassed to read in 6 months — cut.
- Anything that names a confidential entity — replace with a generic.
- Anything that adds words without adding meaning — cut.

### Step 3: Image suggestion

Every post gets one image suggestion. Two options:

**Mermaid diagram** (preferred for technical content):
```
graph LR
    A[Problem] --> B[Approach]
    B --> C[Result]
```

**Image prompt** for an external generator:
- Abstract visualization of the technical concept
- Minimal diagram aesthetic
- Code-editor-inspired illustration

### Step 4: Review (always — never skip)

Show the user three things side by side:

1. English post body (what would actually publish)
2. Translation into the user's language (for review)
3. The image suggestion and hashtags (if any)

Wait for explicit OK. "Looks fine" is not OK; ask for refinements.

### Step 5: Save

Write to `<drafts-dir>/YYYY-MM-DD-<slug>.md`:

```markdown
# {title}

## Post

{English body, with line breaks preserved}

## Image

### Mermaid
{diagram}

### Image prompt
{prompt for generator}

## Hashtags
#tag1 #tag2 #tag3

## Meta
- Category: {category}
- Based on: {source PR/issue}
- Created: {date}
```

### Step 6: Publish (gated)

Only the English body in the "## Post" section gets published. The
publish step is `[irreversible]` per the `safe-autonomy` taxonomy — get
explicit confirmation that names the post being published before
executing.

## Configuration

| Setting | Where |
|---------|-------|
| Drafts directory | `~/.config/linkedin-draft/drafts/` (default) |
| Translation target language | User's primary language from `whoami` |
| LinkedIn API credentials | Set up via your own provider |

## Hashtag Pool

Keep it small. Three to five tags max per post, drawn from:

```
#SoftwareEngineering #DeveloperProductivity #AIAssistedDevelopment
#ClaudeCode #BuildInPublic #EngineeringCulture #LessonsLearned
```

Don't stuff. Five relevant tags beat fifteen generic ones.

## Tips

- One insight per post. Two insights is two posts.
- The first three lines are what shows above "See more" on LinkedIn —
  make them load-bearing.
- Before / after structure tends to earn the most genuine engagement.
  "Here's what I was doing, here's what changed, here's the result."
- Skip a week when you have nothing honest to say. Posting cadence is
  not a virtue; not posting filler is.
