-- Herdr-style keys: press Ctrl+B, release it, then press the action key.
-- Keys use unshifted names (US layout), with explicit shift modifiers.
-- Escape cancels a pending prefix. Reload with: rex config reload
-- Rex-only actions and the client's existing shortcuts are left unchanged.

require("plannotator.annotate").setup({})

-- Rex tabs correspond to Herdr tabs.
rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>n", "client.tab.next")
rex.bind("ctrl+b>p", "client.tab.previous")
rex.bind("ctrl+b>shift+t", "client.tab.rename")
rex.bind("ctrl+b>shift+x", "client.tab.close")
for index = 1, 9 do
	rex.bind("ctrl+b>" .. index, "client.tab.goto", { index = index })
end

-- Panes: split, select, zoom, close, and break out into a new tab.
rex.bind("ctrl+b>v", "pane.split", { direction = "right" })
rex.bind("ctrl+b>-", "pane.split", { direction = "down" })
rex.bind("ctrl+b>tab", "pane.focus_next")
rex.bind("ctrl+b>shift+tab", "pane.focus_previous")
rex.bind("ctrl+b>shift+p", "pane.rename")
rex.bind("ctrl+b>z", "pane.zoom")
rex.bind("ctrl+b>x", "pane.close")
rex.bind("ctrl+b>shift+1", "pane.move_to_new_tab") -- !

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+b>" .. key, "pane.focus", { direction = direction })
end

-- Keep tmux's resize shortcuts as a fallback for Herdr's resize mode.
for _, direction in ipairs({ "left", "right", "up", "down" }) do
	-- Ctrl+arrow resizes one step, Alt+arrow resizes five.
	-- Each resize requires the prefix (no tmux-style repeat timer).
	rex.bind("ctrl+b>ctrl+" .. direction, "pane.resize", {
		direction = direction,
		amount = 1,
	})
	rex.bind("ctrl+b>alt+" .. direction, "pane.resize", {
		direction = direction,
		amount = 5,
	})
end

-- Rex sessions correspond to Herdr workspaces.
rex.bind("ctrl+b>w", "session.switch")
rex.bind("ctrl+b>shift+n", "session.new")
rex.bind("ctrl+b>shift+w", "session.rename")
rex.bind("ctrl+b>shift+d", "session.close")
-- Herdr has no default workspace-cycle keys; retain the tmux shortcuts.
rex.bind("ctrl+b>shift+9", "session.previous") -- (
rex.bind("ctrl+b>shift+0", "session.next") -- )

-- Worktrees via worktrunk.
-- Each picker opens in a floating pane; each worktree opens as its own session.
require("worktrunk").setup({
	merge_flags = { "--no-squash" },
})
rex.bind("ctrl+b>shift+g", "worktree_switch_current")
rex.bind("ctrl+b>d", "worktree_remove")
rex.bind("ctrl+b>shift+m", "worktree_merge")

-- Shared UI actions.
rex.bind("ctrl+b>s", "client.settings")
rex.bind("ctrl+b>b", "client.sidebar.toggle")
rex.bind("ctrl+b>shift+r", "client.config.reload")

-- Scrollback/copy mode and paste from the clipboard (tmux fallbacks).
rex.bind("ctrl+b>[", "pane.copy_mode.enter")
rex.bind("ctrl+b>]", "pane.paste")

-- Send a literal Ctrl+B to the terminal (including nested tmux).
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

rex.bind("cmd+r", "client.mode.enter", { name = "resize" })

rex.bind("resize/h", "pane.resize", { direction = "left" })
rex.bind("resize/l", "pane.resize", { direction = "right" })
rex.bind("resize/j", "pane.resize", { direction = "up" })
rex.bind("resize/k", "pane.resize", { direction = "down" })
