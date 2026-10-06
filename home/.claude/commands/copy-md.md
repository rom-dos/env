---
description: Copy the whole session to the clipboard as markdown
allowed-tools: Bash(~/.claude/scripts/session-to-md.sh:*)
---

!`~/.claude/scripts/session-to-md.sh "${CLAUDE_SESSION_ID}" | pbcopy && echo "Copied session ${CLAUDE_SESSION_ID} to clipboard as markdown."`

Reply with only the line above, nothing else.
