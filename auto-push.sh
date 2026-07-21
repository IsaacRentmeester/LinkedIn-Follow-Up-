#!/usr/bin/env bash
# Auto-commit and push tracker/roster changes so GitHub + Vercel update with no manual step.
# Requires a one-time setup: an 'auto' remote with an embedded GitHub token (HTTPS).
set -e
cd "$(dirname "$0")"
if git diff --quiet && git diff --cached --quiet; then
  echo "auto-push: nothing to commit"
  exit 0
fi
MSG="${1:-Auto-update tracker/roster $(date +%Y-%m-%d\ %H:%M)}"
git add -A
git commit -m "$MSG"
git push auto main
echo "auto-push: pushed -> GitHub (Vercel will auto-deploy)"
