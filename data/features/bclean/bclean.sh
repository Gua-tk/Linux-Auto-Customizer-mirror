#!/usr/bin/env bash

bclean()
{
  if [ "$1" == "--interactive" ] || [ "$1" == "-i" ]; then
    current="$(git branch --show-current)"
    git branch --merged \
    | sed '/^\** *develop$/d' \
    | sed '/^\** *master$/d' \
    | sed "/^\** *${current}/d" >/tmp/merged-branches \
    && grep -q '[^[:space:]]' < "/tmp/merged-branches" \
    && nano /tmp/merged-branches \
    && grep -q '[^[:space:]]' < "/tmp/merged-branches" \
    && xargs git branch -d </tmp/merged-branches
    unset current
  else
    # Delete gone
    git fetch -p && \
    for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do
      git branch -D "${branch}"
    done

    # Delete without remote
    IFS=$'\n'
    git fetch -p && \
    for line in $(git for-each-ref --format '%(refname) %(upstream)' refs/heads); do

      # If the second field is empty, it has no upstream
      if [ -z "$(echo "${line}" | cut -d " " -f2)" ]; then
        # Detect name and delete it
        git branch -D "$(echo "${line}" | cut -d " " -f1 | rev | cut -d "/" -f1 | rev)"
      fi
    done

    # delete merged
    current="$(git branch --show-current)"
    git branch --merged \
    | sed '/^\** *develop$/d' \
    | sed '/^\** *master$/d' \
    | sed "/^\** *${current}/d" >/tmp/merged-branches \
    && grep -q '[^[:space:]]' < "/tmp/merged-branches" \
    && xargs git branch -d </tmp/merged-branches
    unset current

  fi
}

alias git-branch-clean="bclean"
