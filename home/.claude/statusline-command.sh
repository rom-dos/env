#!/bin/bash
# Claude Code status line: directory | git branch | model | context remaining %

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir')
short_dir=$(basename "$dir")

branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)

model=$(echo "$input" | jq -r '.model.display_name')

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

DIM='\033[2m'
RESET='\033[0m'

printf "${DIM}%s${RESET}" "$short_dir"

if [ -n "$branch" ]; then
  printf " ${DIM}(%s)${RESET}" "$branch"
fi

printf " ${DIM}| %s${RESET}" "$model"

if [ -n "$remaining" ]; then
  printf " ${DIM}| Ctx: %s%% left${RESET}" "$remaining"
fi
