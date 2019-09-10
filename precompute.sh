#!/usr/bin/env bash

# if there are changes, aka. git status is not empty
GIT_STATUS=$(git status -s)
if [[ -n "$GIT_STATUS" ]]; then
  echo "There are uncommitted changes:"
  echo "$GIT_STATUS"
  echo "Please commit first."
  exit 1
fi

echo "All changes are committed. Continuing..."
