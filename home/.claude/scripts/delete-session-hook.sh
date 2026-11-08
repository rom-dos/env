#!/usr/bin/env bash
# UserPromptSubmit hook: when the prompt is exactly "/delete-session", delete this session's
# transcript (so it no longer shows in /resume) and drop the prompt (exit 2) so it never reaches the model.
input=$(cat)
prompt=$(jq -r '.prompt // ""' <<<"$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
[[ "$prompt" == "/delete-session" ]] || exit 0

transcript=$(jq -r '.transcript_path // ""' <<<"$input")
if [[ "$transcript" != *.jsonl || ! -f "$transcript" ]]; then
  echo "delete-session: transcript not found ($transcript)" >&2
  exit 2
fi
rm -f "$transcript"
rm -rf "${transcript%.jsonl}" # per-session dir (subagent transcripts etc.), if any
echo "Session deleted. Run /clear to start a new one." >&2
exit 2
