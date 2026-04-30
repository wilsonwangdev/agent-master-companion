#!/bin/bash
set -euo pipefail

git fetch -p

gone=$(git branch -v | grep '\[gone\]' | awk '{print $1}')

if [ -z "$gone" ]; then
  echo "No stale branches to clean."
  exit 0
fi

echo "Deleting stale branches:"
echo "$gone"
echo "$gone" | xargs git branch -D

echo "Done."
