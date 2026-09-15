#!/usr/bin/env bash
# Rebase this fork's local patches on top of the latest cabird/loseit-mcp.
# Safe to re-run: does nothing if already up to date, never force-pushes for you.
set -euo pipefail

UPSTREAM_URL="https://github.com/cabird/loseit-mcp.git"
UPSTREAM_BRANCH="main"

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "$UPSTREAM_URL"
fi
git fetch upstream "$UPSTREAM_BRANCH"

behind=$(git rev-list --count "HEAD..upstream/$UPSTREAM_BRANCH")
if [ "$behind" -eq 0 ]; then
  echo "Already up to date with upstream/$UPSTREAM_BRANCH."
  exit 0
fi

echo "$behind commit(s) behind upstream/$UPSTREAM_BRANCH. Rebasing local patches on top..."
if git rebase "upstream/$UPSTREAM_BRANCH"; then
  echo
  echo "Rebase succeeded cleanly. Review the result, then:"
  echo "  git push --force-with-lease origin main"
else
  echo
  echo "Rebase hit conflicts -- resolve them, then 'git rebase --continue'."
  echo "(Or 'git rebase --abort' to back out and try 'git merge upstream/$UPSTREAM_BRANCH' instead,"
  echo " which keeps a merge commit instead of rewriting history, if you'd rather not force-push.)"
  exit 1
fi
