#!/usr/bin/env bash
# Convert a Claude Code session transcript to markdown (user prompts + Claude's text replies).
# Usage: session-to-md.sh [session-id | path/to/session.jsonl]
# With no argument (or an unexpanded placeholder), uses the most recently modified session in any project.
set -euo pipefail

arg="${1:-}"
if [[ -f "$arg" ]]; then
  f="$arg"
elif [[ -n "$arg" && "$arg" != *'$'* ]] && f=$(ls ~/.claude/projects/*/"$arg".jsonl 2>/dev/null | head -1) && [[ -n "$f" ]]; then
  :
else
  f=$(ls -t ~/.claude/projects/*/*.jsonl | head -1)
fi

jq -r '
  select(.isMeta != true) |
  if .type=="user" and (.message.content|type)=="string" and (.message.content|startswith("<")|not)
    then "## User\n\n" + .message.content + "\n"
  elif .type=="assistant"
    then (.message.content | map(select(.type=="text") | .text) | join("\n\n")) as $t
         | if $t=="" then empty else "## Claude\n\n" + $t + "\n" end
  else empty end' "$f"
