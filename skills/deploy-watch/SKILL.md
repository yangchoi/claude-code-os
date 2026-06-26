---
name: deploy-watch
description: Polls a deployment target in the background and sends a desktop notification when it completes or fails. Use when you've pushed a change and don't want to babysit the deploy UI, when you want to keep coding while a build runs, or when you need to know immediately if a deploy fails.
---

# deploy-watch

Background deploy monitor with desktop notifications. Currently supports
Vercel (via GitHub Deployments API) and AWS ECS.

## Overview

Pushing a change and then sitting on the deploy dashboard is a productivity
sink. Tab away and you forget about it; tab back and you've lost ten minutes.

This skill watches the deploy from the background. When it finishes — success
or failure — you get a desktop notification with the result.

## Usage

```
/deploy-watch vercel <github-repo>       Watch a Vercel deploy via GitHub
/deploy-watch ecs <service-name>         Watch an ECS service rollout
/deploy-watch status                     Show what's being watched
```

## Vercel (via GitHub Deployments)

```bash
ORG="${DEPLOY_WATCH_ORG:?set DEPLOY_WATCH_ORG=your-github-org}"
REPO=$1

# Snapshot the current latest deployment
INITIAL_ID=$(gh api repos/$ORG/$REPO/deployments --jq '.[0].id')

# Poll for a new one
while true; do
  sleep 30
  LATEST=$(gh api repos/$ORG/$REPO/deployments --jq '.[0]')
  LATEST_ID=$(echo "$LATEST" | jq -r '.id')

  [ "$LATEST_ID" = "$INITIAL_ID" ] && continue

  STATUS=$(gh api repos/$ORG/$REPO/deployments/$LATEST_ID/statuses --jq '.[0].state')

  case "$STATUS" in
    success)
      notify "$REPO deploy succeeded" "Glass"
      break
      ;;
    failure|error)
      notify "$REPO deploy failed" "Basso"
      break
      ;;
  esac
done
```

## ECS

```bash
CLUSTER="${DEPLOY_WATCH_ECS_CLUSTER:?set DEPLOY_WATCH_ECS_CLUSTER=your-cluster}"
SERVICE=$1

while true; do
  sleep 30
  STATE=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
    --query 'services[0].deployments' --output json)

  PRIMARY_COUNT=$(echo "$STATE" | jq '[.[] | select(.status == "PRIMARY")] | length')
  RUNNING=$(echo "$STATE" | jq '.[0].runningCount')
  DESIRED=$(echo "$STATE" | jq '.[0].desiredCount')

  # Steady state: exactly one PRIMARY, running == desired
  if [ "$PRIMARY_COUNT" -eq 1 ] && [ "$RUNNING" -eq "$DESIRED" ]; then
    notify "$SERVICE rollout complete" "Glass"
    break
  fi
done
```

## Desktop Notifications

```bash
# macOS
notify() {
  osascript -e "display notification \"$1\" with title \"deploy-watch\" sound name \"$2\""
}

# Linux (notify-send)
notify() {
  notify-send "deploy-watch" "$1"
}
```

## Configuration

| Env var | Purpose |
|---------|---------|
| `DEPLOY_WATCH_ORG` | GitHub org or user that owns the repo (Vercel mode) |
| `DEPLOY_WATCH_ECS_CLUSTER` | ECS cluster name |

## Running in the Background

The poll loop is meant to run in the background so your terminal is free.
In Claude Code, launch the Bash call with `run_in_background: true`. From
a regular shell, append `&` and `disown`.

## Requirements

- `gh` CLI authenticated (for Vercel mode)
- `aws` CLI configured (for ECS mode)
- macOS or Linux desktop (for notifications)

## Tips

- Run `/deploy-watch` right after merging a PR — by the time you've
  context-switched, the result is on its way.
- Failure notifications use a different sound (`Basso` vs `Glass` on macOS)
  so you can tell from across the room.
- For ECS, "steady state" means rollout is done. Mid-rollout you'll see
  PRIMARY + ACTIVE deployments coexisting.
