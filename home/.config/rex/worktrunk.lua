--[[

Worktrunk integration for Rex: switch to, create, merge and remove git
worktrees with worktrunk (`wt`), one Rex session per worktree.

* Required from init.lua, it defines the actions (see M.setup). An action
opens a floating pane running this same file as a `rex do` script.

* Run by `rex do` in that floating pane, it shows the fzf picker, runs
worktrunk, opens/closes the worktree's session, and exits, which closes
the floating pane.

The picker has to live in a terminal (fzf, worktrunk's confirmation prompts and
hook output need one), and config actions are capped at 30 seconds, so the
long-running half is a script rather than the action itself.

Selecting the new session from the script needs Remote Control on in Rex.app
(Settings > Server > Client Info). Without it the session is still created
and the picker says which one to switch to.

--]]

local M = {}

local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local TERMINAL = "com.superlogical.terminal"

M.defaults = {
	-- Floating picker pane, as { x, y, w, h } fractions of the window.
	bounds = { 0.15, 0.1, 0.7, 0.8 },
	-- List remote-tracking branches (origin/foo) in every switch picker, not
	-- just the "local or remote branches" one.
	show_remote_branches = false,
	-- Turn a typed new branch name into a slug: "Fix Login Bug" → "fix-login-bug".
	slugify_new_branches = false,
	-- Wait for a key after worktrunk succeeds so its output can be read.
	-- hold_on_<action> (create, merge, remove) wins over hold_on_success.
	hold_on_success = false,
	hold_on_create = nil,
	hold_on_merge = nil,
	hold_on_remove = nil,
	-- Extra `wt merge` flags. Only flags that keep the merge-then-remove flow
	-- intact are accepted (see MERGE_FLAGS).
	merge_flags = {},
	-- Layout for a newly created worktree session:
	--   ┌──────────────┬──────────────┐
	--   │ install/build│              │
	--   │ /dev (30%)   │  agent       │
	--   ├──────────────┤  (40%)       │
	--   │ shell (70%)  │              │
	--   └──────────────┴──────────────┘
	-- false opens a single shell instead.
	layout = true,
	agent_command = "cl",
	build_script = "build",
	dev_script = "dev",
}

local MERGE_FLAGS = {
	["--no-squash"] = true,
	["--no-rebase"] = true,
	["--no-ff"] = true,
	["--no-commit"] = true,
	["--no-hooks"] = true,
	["--stage=all"] = true,
	["--stage=tracked"] = true,
	["--stage=none"] = true,
}

-- Small helpers

local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lines(s)
	local out = {}
	for line in (s or ""):gmatch("[^\n]+") do
		out[#out + 1] = line
	end
	return out
end

local function basename(p)
	return (p:gsub("/+$", ""):match("([^/]+)$")) or p
end

local function dirname(p)
	return (p:gsub("/+$", ""):match("^(.*)/[^/]*$")) or "."
end

local function color(code, msg)
	return "\27[" .. code .. "m" .. msg .. "\27[0m"
end

local function say(code, msg)
	io.write(color(code, msg), "\n")
	io.flush()
end

local function file_exists(p)
	local f = io.open(p, "r")
	if f then
		f:close()
	end
	return f ~= nil
end

-- Run a command and return its trimmed stdout, or nil when it failed.
local function run(argv, cwd)
	local r = rex.exec(argv, { cwd = cwd })
	if r and r.ok then
		return trim(r.stdout)
	end
	return nil
end

local function git(cwd, ...)
	return run({ "git", ... }, cwd)
end

local function realpath(p)
	if not p or p == "" then
		return p
	end
	return run({ "realpath", p }) or p
end

-- Run an interactive command on the pane's terminal: stdin and stderr (and
-- stdout, unless capture is set) go to /dev/tty, so fzf-free prompts such as
-- worktrunk's approvals and hook output behave as if typed at a shell.
local function tty_exec(argv, opts)
	opts = opts or {}
	local script = 'exec "$@" </dev/tty 2>/dev/tty' .. (opts.capture and "" or " >/dev/tty")
	local cmd = { "sh", "-c", script, "sh" }
	for _, a in ipairs(argv) do
		cmd[#cmd + 1] = a
	end
	return rex.exec(cmd, { cwd = opts.cwd })
end

local function wait_key(msg)
	io.write("\n", msg, " press any key to close")
	io.flush()
	rex.exec({ "bash", "-c", "read -rsn1 </dev/tty" })
end

local function fail(msg)
	io.write(color("31", msg))
	wait_key("")
end

-- Worktrunk helpers

-- A token worktrunk resolves itself: ^ (default), - (previous), or `:` syntax
-- (pr:N, mr:N, a PR/MR URL). Never passed with --create.
local function is_shortcut(name)
	return name == "^" or name == "-" or name:find(":", 1, true) ~= nil
end

local function ref_exists(cwd, name)
	for _, prefix in ipairs({ "refs/heads/", "refs/remotes/" }) do
		local r = rex.exec({ "git", "show-ref", "--quiet", "--verify", prefix .. name }, { cwd = cwd })
		if r and r.ok then
			return true
		end
	end
	return false
end

-- "Fix Login Bug" → "fix-login-bug". Keeps / . _; nil when no valid name is left.
local function branch_slug(cwd, text)
	local s = text:lower()
	s = s:gsub("[^a-z0-9._/]+", "-")
	s = s:gsub("%-*/+%-*", "/")
	s = s:gsub("%.%.+", ".")
	s = s:gsub("/%.+", "/")
	s = s:gsub("^[-/.]+", "")
	s = s:gsub("[-/.]+$", "")
	if s == "" then
		return nil
	end
	local r = rex.exec({ "git", "check-ref-format", "refs/heads/" .. s }, { cwd = cwd })
	if not (r and r.ok) then
		return nil
	end
	return s
end

-- Label for a worktree picked as NAME that worktrunk resolved to BRANCH, e.g.
-- "feat/eager-worktree-focus (pr:16)".
local function switch_label(branch, name)
	if not branch or branch == "" or branch == name then
		return name
	end
	return branch .. " (" .. name .. ")"
end

-- Normalize `wt list --format=json` (schema 1 or 2) to items with top-level
-- kind, path and is_main.
local function list_items(text)
	local data = rex.json.decode(text or "")
	if type(data) ~= "table" then
		return nil
	end
	local raw = data.items or data
	local items = {}
	for _, it in ipairs(raw) do
		local wt = type(it.worktree) == "table" and it.worktree or nil
		it.kind = it.kind or (wt and "worktree" or "branch")
		it.path = it.path or (wt and wt.path)
		it.is_main = it.is_main or (wt and wt.main) or false
		items[#items + 1] = it
	end
	return items
end

local function worktree_items(cwd)
	local r = rex.exec({ "wt", "list", "--format=json" }, { cwd = cwd })
	if not (r and r.ok) then
		say("31", "failed to list worktrees")
		rex.sleep(2)
		return nil
	end
	local items = list_items(r.stdout)
	if not items then
		say("31", "unsupported worktrunk list output")
		rex.sleep(2)
	end
	return items
end

local function main_worktree_path(items)
	for _, it in ipairs(items) do
		if it.kind == "worktree" and it.is_main then
			return it.path
		end
	end
end

local function hold(opts, action, msg)
	local v = opts["hold_on_" .. action]
	if v == nil then
		v = opts.hold_on_success
	end
	if v then
		wait_key(color("32", msg))
	end
end

local function merge_flags(opts, extra)
	local flags, seen = {}, {}
	local function add(f)
		if seen[f] then
			return
		end
		if MERGE_FLAGS[f] then
			seen[f] = true
			flags[#flags + 1] = f
		else
			say("33", "Warning: unsupported merge_flags entry " .. f .. "; ignoring it")
		end
	end
	local configured = opts.merge_flags or {}
	if type(configured) == "string" then
		local t = {}
		for f in configured:gmatch("%S+") do
			t[#t + 1] = f
		end
		configured = t
	end
	for _, f in ipairs(configured) do
		add(f)
	end
	for _, f in ipairs(extra or {}) do
		add(f)
	end
	return flags
end

-- fzf over CANDIDATES (a list of strings); returns the selection or nil.
local function pick(cwd, candidates, prompt, header)
	local r = rex.exec({
		"fzf",
		"--reverse",
		"--info=inline",
		"--border=none",
		"--margin=0",
		"--prompt=" .. prompt,
		"--header=" .. header,
	}, { cwd = cwd, stdin = table.concat(candidates, "\n") .. "\n" })
	if not (r and r.ok) then
		return nil
	end
	local choice = trim(r.stdout)
	if choice == "" then
		return nil
	end
	return choice
end

---------------------------------------------------------------------------
-- Sessions: one per worktree
---------------------------------------------------------------------------

-- Worktree path → session id, so a session is found again even after its panes
-- cd elsewhere or it is renamed.
local function state_path()
	local base = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
	return base .. "/rex/worktrunk-sessions.json"
end

local function load_state()
	local f = io.open(state_path(), "r")
	if not f then
		return {}
	end
	local data = rex.json.decode(f:read("*a"))
	f:close()
	return type(data) == "table" and data or {}
end

local function save_state(state)
	local p = state_path()
	rex.exec({ "mkdir", "-p", dirname(p) })
	local f = io.open(p, "w")
	if not f then
		return
	end
	f:write(rex.json.encode(state) or "{}")
	f:close()
end

local function sessions()
	local r = rex.call("session.list")
	return (r and r.sessions) or {}
end

-- A terminal's working directory: what the shell reported, else the cwd of its
-- foreground process or of the shell itself.
local function block_cwd(sid, bid)
	local pwd = rex.block.call(TERMINAL, "pwd", { session_id = sid, block_id = bid })
	if pwd and (pwd.pwd or pwd.path) then
		return pwd.pwd or pwd.path
	end
	local p = rex.block.call(TERMINAL, "process", { session_id = sid, block_id = bid })
	if not p then
		return nil
	end
	if p.foreground and p.foreground.cwd then
		return p.foreground.cwd
	end
	for _, a in ipairs(p.ancestors or {}) do
		if a.cwd then
			return a.cwd
		end
	end
end

local function inside(dir, root)
	return dir == root or dir:sub(1, #root + 1) == root .. "/"
end

-- The session open on the worktree at PATH (already canonical), or nil: the one
-- recorded when it was opened, else one whose terminals all sit in the worktree.
local function find_session(path)
	local live = {}
	for _, s in ipairs(sessions()) do
		live[s.session_id] = true
	end

	local state = load_state()
	local sid = state[path]
	if sid and live[sid] then
		return sid
	end

	for _, s in ipairs(sessions()) do
		local r = rex.session.list_blocks({ session_id = s.session_id })
		local count, all_in = 0, true
		for _, b in ipairs((r and r.blocks) or {}) do
			if b.creator_name == TERMINAL and b.placement == "placed" then
				local cwd = block_cwd(s.session_id, b.block_id)
				if cwd then
					count = count + 1
					if not inside(realpath(cwd), path) then
						all_in = false
						break
					end
				end
			end
		end
		if count > 0 and all_in then
			return s.session_id
		end
	end
end

local function select_session(sid, label)
	local ok, err = pcall(rex.client.queue, "session.select", { session_id = sid })
	if not ok then
		say("33", "Opened session '" .. label .. "', but Rex.app refused to switch to it:")
		say("33", tostring(err))
		wait_key("")
	end
end

-- Install/build/dev line for the package manager whose lockfile is in DIR.
local function setup_command(dir, opts)
	local pm
	if file_exists(dir .. "/bun.lock") or file_exists(dir .. "/bun.lockb") then
		pm = "bun"
	elseif file_exists(dir .. "/pnpm-lock.yaml") then
		pm = "pnpm"
	elseif file_exists(dir .. "/yarn.lock") then
		pm = "yarn"
	elseif file_exists(dir .. "/package-lock.json") then
		pm = "npm"
	end
	if not pm then
		return nil
	end

	local scripts = {}
	local f = io.open(dir .. "/package.json", "r")
	if f then
		local pkg = rex.json.decode(f:read("*a"))
		f:close()
		scripts = (type(pkg) == "table" and pkg.scripts) or {}
	end
	local cmd = pm .. " install"
	if scripts[opts.build_script] then
		cmd = cmd .. " && " .. pm .. " run " .. opts.build_script
	end
	if scripts[opts.dev_script] then
		cmd = cmd .. " && " .. pm .. " run " .. opts.dev_script
	end
	return cmd
end

local function session_layout(dir, opts)
	local L = rex.layout
	local function term(input)
		return L.block({ flavor = SHELL_FLAVOR, options = { cwd = dir, initial_input = input } })
	end
	if not opts.layout then
		return term(nil), 1
	end
	local setup = setup_command(dir, opts)
	local agent = opts.agent_command ~= "" and opts.agent_command or nil
	-- Blocks come back in layout order: setup, shell, agent. Focus the agent.
	return L.horizontal(0.6, L.vertical(0.3, term(setup and setup .. "\n"), term(nil)), term(agent and agent .. "\n")),
		3
end

-- Switch to the worktree's session, creating it (with the layout) if needed.
local function open_session(path, label, opts)
	local sid = find_session(path)
	if not sid then
		local layout, focus_index = session_layout(path, opts)
		local created, err = rex.call("session.create", {
			label = label,
			initial_windows = { { window_label = label, layout = layout } },
		})
		if not created then
			return fail("failed to create session: " .. tostring(err))
		end
		sid = created.session_id
		local blocks = created.initial_windows[1].block_ids
		rex.session.focus_block({ session_id = sid, block_id = blocks[focus_index] })
		local state = load_state()
		state[path] = sid
		save_state(state)
	end
	select_session(sid, label)
end

-- Destroy the worktree's session once the worktree is gone. When that session is
-- the one the picker runs in, show the main worktree's session first.
local function close_session(sid, path, mainpath)
	local state = load_state()
	if state[path] then
		state[path] = nil
		save_state(state)
	end
	if not sid then
		return
	end
	if sid == rex.session_id and mainpath then
		local main_sid = find_session(realpath(mainpath))
		if main_sid and main_sid ~= sid then
			pcall(rex.client.queue, "session.select", { session_id = main_sid })
		end
	end
	rex.call("session.destroy", { session_id = sid })
end

---------------------------------------------------------------------------
-- Script operations (run in the floating pane)
---------------------------------------------------------------------------

local function op_open(a)
	local cwd = a.cwd
	local base, base_label = nil, "default branch"
	if a.base == "current" then
		base = "@"
		local branch = git(cwd, "branch", "--show-current")
		if branch and branch ~= "" then
			base_label = "current branch (" .. branch .. ")"
		else
			local head = git(cwd, "rev-parse", "--short", "HEAD")
			base_label = head and ("current HEAD (" .. head .. ")") or "current branch"
		end
	end

	local refs = { "refs/heads" }
	if a.remotes or a.show_remote_branches then
		refs[#refs + 1] = "refs/remotes"
	end

	-- fzf streams its candidates: refs answer instantly, `wt list` (which stats
	-- every checkout) follows while the picker is already up. --print-query
	-- returns a typed-but-unmatched name; alt-↵ forces the typed name.
	local fzf = assert(rex.exec.start({
		"fzf",
		"--print-query",
		"--reverse",
		"--info=inline",
		"--border=none",
		"--margin=0",
		"--bind=alt-enter:print-query",
		"--prompt=worktree ❯ ",
		"--header=↵ on a match → switch · type a new name + ↵ → create from "
			.. base_label
			.. " · alt-↵ → force typed name · esc → cancel",
	}, { cwd = cwd, stdin = true }))

	local seen = {}
	local function feed(name)
		if name and name ~= "" and not seen[name] then
			seen[name] = true
			fzf:write(name .. "\n")
		end
	end

	local argv = { "git", "for-each-ref", "--format=%(refname) %(refname:short)" }
	for _, r in ipairs(refs) do
		argv[#argv + 1] = r
	end
	local r = rex.exec(argv, { cwd = cwd })
	for _, line in ipairs(lines(r and r.stdout)) do
		local full, short = line:match("^(%S+) (.+)$")
		if full and not full:match("/HEAD$") then
			feed(short)
		end
	end

	local list = rex.exec.start({ "wt", "list", "--format=json" }, { cwd = cwd })
	while fzf:running() do
		if list and not list:running() then
			local lr = list:wait()
			for _, it in ipairs((lr and lr.ok and list_items(lr.stdout)) or {}) do
				feed(it.branch)
			end
			fzf:close_stdin()
			list = nil
		end
		rex.sleep(0.05)
	end
	if list then
		list:kill()
	end

	local res = fzf:wait()
	if not res or res.code > 1 then
		return
	end -- 130 = esc
	local out = lines(res.stdout)
	local name = trim(out[#out])
	if name == "" then
		return
	end

	if a.slugify_new_branches and not is_shortcut(name) and not ref_exists(cwd, name) then
		local slug = branch_slug(cwd, name)
		if not slug then
			return fail("no valid branch name in: " .. name)
		end
		name = slug
	end

	local wtargs
	if is_shortcut(name) or ref_exists(cwd, name) then
		wtargs = { "wt", "switch", name }
	else
		wtargs = { "wt", "switch", "--create", name }
		if base then
			wtargs[#wtargs + 1] = "--base"
			wtargs[#wtargs + 1] = base
		end
	end
	wtargs[#wtargs + 1] = "--no-cd"
	wtargs[#wtargs + 1] = "--format=json"

	local sw = tty_exec(wtargs, { cwd = cwd, capture = true })
	if not (sw and sw.ok) then
		return fail("wt switch failed (see above).")
	end

	local result = rex.json.decode(sw.stdout) or {}
	local label = switch_label(result.branch, name)
	local path = result.path
	if not path or path == "" then
		for _, it in ipairs(worktree_items(cwd) or {}) do
			if it.kind == "worktree" and it.branch == name then
				path = it.path
				break
			end
		end
	end
	if not path then
		return fail("worktrunk returned no worktree path for: " .. name)
	end

	if result.action == "created" then
		hold(a, "create", "created worktree " .. label .. ".")
	end

	-- The main worktree's session is named after the repository, not its branch.
	local common = git(path, "rev-parse", "--path-format=absolute", "--git-common-dir")
	local gitdir = git(path, "rev-parse", "--path-format=absolute", "--git-dir")
	if common and common == gitdir then
		local root = basename(common) == ".git" and dirname(common) or common
		label = (basename(root):gsub("%.git$", ""))
	end

	open_session(realpath(path), label, a)
end

local function op_remove(a)
	local cwd = a.cwd
	local items = worktree_items(cwd)
	if not items then
		return
	end

	local cands = {}
	for _, it in ipairs(items) do
		if it.kind == "worktree" and it.branch and not it.is_main then
			cands[#cands + 1] = it.branch
		end
	end
	if #cands == 0 then
		say("33", "No removable worktrees (only the main worktree exists).")
		return rex.sleep(2)
	end

	local name =
		pick(cwd, cands, "remove worktree ❯ ", "↵ to remove (worktrunk will ask to confirm) · esc to cancel")
	if not name then
		return
	end

	local wtpath
	for _, it in ipairs(items) do
		if it.kind == "worktree" and it.branch == name then
			wtpath = it.path
		end
	end
	local mainpath = main_worktree_path(items)
	local path = realpath(wtpath)
	local sid = find_session(path)

	-- wt remove asks for approval itself and refuses unmerged/dirty worktrees, so
	-- run it interactively. -C from the main worktree; --foreground so the session
	-- isn't closed before the worktree is really gone.
	local r = tty_exec({ "wt", "remove", "--foreground", "-C", mainpath, name }, { cwd = cwd })
	if not (r and r.ok) then
		return fail("wt remove failed (see above).")
	end

	hold(a, "remove", "removed " .. name .. ".")
	close_session(sid, path, mainpath)
end

local function op_merge(a)
	local cwd = a.cwd
	local flags = merge_flags(a, a.no_squash and { "--no-squash" } or {})
	local items = worktree_items(cwd)
	if not items then
		return
	end

	-- Merge the worktree the action was run from into a picked target branch.
	local toplevel = realpath(git(cwd, "rev-parse", "--show-toplevel"))
	local wtpath, name
	for _, it in ipairs(items) do
		if it.kind == "worktree" and not it.is_main and it.path and realpath(it.path) == toplevel then
			wtpath, name = it.path, it.branch
			break
		end
	end
	if not wtpath or not name then
		io.write(color("33", "Not inside a linked worktree — run merge from the worktree you want to merge."))
		return wait_key("")
	end

	local targets = {}
	local refs = git(wtpath, "for-each-ref", "--sort=-committerdate", "--format=%(refname:short)", "refs/heads")
	for _, b in ipairs(lines(refs)) do
		if b ~= name then
			targets[#targets + 1] = b
		end
	end
	if #targets == 0 then
		say("33", "No other local branches to merge into.")
		return rex.sleep(2)
	end

	local shown = #flags > 0 and (" " .. table.concat(flags, " ")) or ""
	local target = pick(
		cwd,
		targets,
		"merge " .. name .. " into ❯ ",
		"↵ to run wt merge <target>" .. shown .. " and remove this worktree · esc to cancel"
	)
	if not target then
		return
	end

	local path = realpath(wtpath)
	local sid = find_session(path)
	local mainpath = main_worktree_path(items)

	-- --no-remove: wt merge's own removal runs in the background and would race
	-- the session close; the foreground `wt remove` below does it instead.
	local argv = { "wt", "merge", "--no-remove", "-C", wtpath }
	for _, f in ipairs(flags) do
		argv[#argv + 1] = f
	end
	argv[#argv + 1] = target
	local r = tty_exec(argv, { cwd = cwd })
	if not (r and r.ok) then
		return fail("wt merge failed (see above).")
	end

	r = tty_exec({ "wt", "remove", "--foreground", "-C", mainpath, name }, { cwd = cwd })
	if not (r and r.ok) then
		return fail("merged, but wt remove failed (see above).")
	end

	hold(a, "merge", "merged " .. name .. " into " .. target .. " and removed the worktree.")
	close_session(sid, path, mainpath)
end

function M.script(a)
	-- Calls on other sessions (finding, creating, destroying) need this.
	rex.call("session.attach_all", { event_scope = "session" })
	local ops = { open = op_open, remove = op_remove, merge = op_merge }
	local op = ops[a.op]
	if not op then
		error("unknown worktrunk op: " .. tostring(a.op), 0)
	end
	if not git(a.cwd, "rev-parse", "--show-toplevel") then
		return fail("not in a git repository: " .. tostring(a.cwd))
	end
	op(a)
end

---------------------------------------------------------------------------
-- Config: actions that open the floating picker
---------------------------------------------------------------------------

local function script_path()
	local src = debug.getinfo(1, "S").source or ""
	local p = src:match("^@(/.+)$")
	if p then
		return p
	end
	local base = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
	return base .. "/rex/worktrunk.lua"
end

local function focused_cwd(ctx)
	if not ctx.block_id then
		return nil
	end
	return block_cwd(ctx.session_id, ctx.block_id)
end

local function open_picker(ctx, opts, title, extra)
	local cwd = focused_cwd(ctx) or os.getenv("HOME")
	local args = { cwd = cwd }
	for k, v in pairs(opts) do
		if k ~= "bounds" then
			args[k] = v
		end
	end
	for k, v in pairs(extra) do
		args[k] = v
	end

	local _, err = rex.session.new_layer({
		bounds = opts.bounds,
		focus = true,
		layout = rex.layout.block({
			flavor = SHELL_FLAVOR,
			label = title,
			options = {
				cwd = cwd,
				command = { "rex", "do", script_path(), "--args", rex.json.encode(args) },
			},
		}),
	})
	if err ~= nil then
		error(err, 0)
	end
end

-- Define the actions. OPTS overrides M.defaults.
function M.setup(opts)
	local o = {}
	for k, v in pairs(M.defaults) do
		o[k] = v
	end
	for k, v in pairs(opts or {}) do
		o[k] = v
	end

	local actions = {
		{
			"worktree_switch",
			"Worktree: switch / create from default branch",
			"Worktrunk — default branch",
			{ op = "open", base = "default" },
		},
		{
			"worktree_switch_current",
			"Worktree: switch / create from current branch",
			"Worktrunk — current branch",
			{ op = "open", base = "current" },
		},
		{
			"worktree_switch_remotes",
			"Worktree: switch / create from local or remote branches",
			"Worktrunk — local and remote branches",
			{ op = "open", base = "default", remotes = true },
		},
		{ "worktree_remove", "Worktree: remove", "Worktrunk — remove", { op = "remove" } },
		{ "worktree_merge", "Worktree: merge into the target branch", "Worktrunk — merge", { op = "merge" } },
		{
			"worktree_merge_no_squash",
			"Worktree: merge into the target branch, keeping every commit",
			"Worktrunk — merge (no squash)",
			{ op = "merge", no_squash = true },
		},
	}
	for _, a in ipairs(actions) do
		local name, title, pane_title, extra = a[1], a[2], a[3], a[4]
		rex.action({
			name = name,
			title = title,
			category = "Worktree",
			keywords = "worktrunk wt git worktree branch",
			run = function(ctx)
				open_picker(ctx, o, pane_title, extra)
			end,
		})
	end
end

-- Run by `rex do` (rex.args is only set in scripts): do the work.
if rex.args ~= nil and rex.args.op ~= nil then
	M.script(rex.args)
end

return M
