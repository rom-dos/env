#!/usr/bin/env bash
# UserPromptSubmit hook: when the prompt is exactly "/copy-md", copy the session as markdown
# and drop the prompt (exit 2) so it never reaches the model.
input=$(cat)
prompt=$(jq -r '.prompt // ""' <<<"$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
[[ "$prompt" == "/copy-md" ]] || exit 0

transcript=$(jq -r '.transcript_path // ""' <<<"$input")
~/.claude/scripts/session-to-md.sh "$transcript" | pbcopy
echo "Copied session to clipboard as markdown." >&2
exit 2
