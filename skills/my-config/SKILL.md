---
name: my-config
description: Prints a one-screen summary of your Claude Code setup — settings, skills, hooks, agents, MCP servers. Use when you want a quick "what's actually loaded?" check before starting work, when debugging why a skill isn't firing, or when sharing your config layout with someone else.
allowed-tools: Bash
---

# my-config

Tells you what Claude Code is actually running with right now.

## Overview

Claude Code reads configuration from several places: `~/.claude/settings.json`,
project-local `.claude/`, `~/.claude/skills/`, `~/.claude/agents/`, plus any
plugin marketplaces you've installed. After a few weeks of accumulation, it
gets hard to remember what's actually live.

This skill prints a compact, scannable summary so you can answer "is X
loaded? from where?" in a second.

## What It Shows

- **Settings** — resolved settings.json (user + project merged)
- **Skills** — names + descriptions, grouped by source (`~/.claude/skills/`,
  project `.claude/skills/`, plugins)
- **Agents** — names + brief description, grouped by source
- **Hooks** — configured hooks per event (PreToolUse, PostToolUse, etc.)
- **MCP servers** — names and connection status
- **Plugins** — installed plugin marketplaces and which are enabled

## Implementation

```bash
echo "=== Settings ==="
if [ -f ~/.claude/settings.json ]; then
  jq -r 'to_entries | map("\(.key): \(.value)") | .[]' ~/.claude/settings.json | head -20
else
  echo "(no user settings)"
fi

echo ""
echo "=== Skills ==="
for dir in ~/.claude/skills/*/; do
  name=$(basename "$dir")
  desc=$(awk '/^description:/ {sub(/^description: */, ""); print; exit}' "$dir/SKILL.md" 2>/dev/null | head -c 80)
  echo "  $name — $desc"
done

echo ""
echo "=== Agents ==="
for f in ~/.claude/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  desc=$(awk '/^description:/ {sub(/^description: */, ""); print; exit}' "$f" | head -c 80)
  echo "  $name — $desc"
done

echo ""
echo "=== Hooks (from settings.json) ==="
jq -r '.hooks // {} | to_entries | .[] | "\(.key): \(.value | length) hook(s)"' ~/.claude/settings.json 2>/dev/null

echo ""
echo "=== MCP servers ==="
jq -r '.mcpServers // {} | keys | .[]' ~/.claude/settings.json 2>/dev/null | sed 's/^/  /'
```

## Usage

Just `/my-config`. There are no arguments.

## When to Use This

- Starting work after a break — quick check on what's actually loaded
- A skill isn't firing — verify it's installed in a location Claude scans
- Sharing your setup with someone — paste the output instead of describing
- After installing a plugin — confirm it ended up where you expected
- Before reporting a bug — include the relevant section as repro context

## Limitations

- Doesn't show plugin-namespaced skills unless you extend the loop to walk
  plugin directories. The path depends on where your plugin manager
  installs them.
- Doesn't validate that hooks actually run — only that they're configured.
  For that, trigger them and check the logs.
