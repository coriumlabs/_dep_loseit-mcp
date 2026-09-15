#!/usr/bin/env bash
# Bump the lose-it git dependency pin to the latest commit on our fork's main,
# and regenerate uv.lock to match. Run from the repo root.
#
# Pinned to an exact commit (not a tracked branch) is deliberate: for a
# reverse-engineered client, you want to choose when a new version gets
# picked up, not have it shift silently under a build. This script just makes
# that choice a one-command operation instead of a manual multi-step chore.
set -euo pipefail

FORK_URL="https://github.com/coriumlabs/_dep_lose-it.git"
FORK_BRANCH="main"

current=$(grep -oP '(?<=_dep_lose-it", rev = ")[a-f0-9]+' pyproject.toml)
latest=$(git ls-remote "$FORK_URL" "refs/heads/$FORK_BRANCH" | cut -f1)

if [ "$latest" = "$current" ]; then
  echo "Already pinned to the latest _dep_lose-it commit ($current)."
  exit 0
fi

echo "Bumping lose-it pin: $current -> $latest"
sed -i "s/$current/$latest/" pyproject.toml

echo "Regenerating uv.lock (via a throwaway container, since uv isn't installed on this host)..."
docker run --rm -v "$PWD":/app -w /app python:3.12-slim sh -c \
  'apt-get update -qq && apt-get install -y -qq git >/dev/null 2>&1 && pip install -q uv && uv lock'

echo
echo "Done. Review the diff:"
git diff pyproject.toml uv.lock
echo
echo "Then: git add pyproject.toml uv.lock && git commit -m 'chore: bump lose-it to $latest' && git push"
echo "...and rebuild the image to actually pick it up: docker compose up -d --build"
