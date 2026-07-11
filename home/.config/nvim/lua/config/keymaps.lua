-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local function smart_save()
  local buf = 0 -- current buffer
  local name = vim.api.nvim_buf_get_name(buf)

  -- case a: buffer does not have a file name yet -> give it one
  if name == "" or name == nil then -- «new / unnamed» buffer
    local dir = assert(vim.env.NVIM_SW_BUFFER_DIR, "NVIM_SW_BUFFER_DIR is not set")
    -- create the directory once if it does not exist
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end

    -- YYYYMMDDHHMMSS.md   (e.g. 20230904150312.md)
    local fullpath = dir .. "/" .. os.date("%Y%m%d%H%M%S") .. ".md"

    -- give that name to the buffer so subsequent :w works normally
    vim.api.nvim_buf_set_name(buf, fullpath) -- ① give it the name
    vim.cmd("silent! filetype detect") -- ② run ft-detection
  end

  -- case b: file already has a name (or we just gave it one) -> write it
  vim.cmd("write") -- same as :w
end

-- 2.  Create a user command (so you can :SmartWrite as well)
vim.api.nvim_create_user_command("SmartWrite", smart_save, {})

-- 3.  Map the command to “z” in normal mode
--     NOTE: “z” is the first key of many default fold commands; you will
--           lose those if you map it like this.
vim.keymap.set("n", "z", "<cmd>SmartWrite<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>z", ":wq<CR>")

-- Better half-page up/down
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keeps search terms in middle of screen
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- alt + '
vim.keymap.set("n", "æ", "<C-d>zz")
-- alt + ;
vim.keymap.set("n", "…", "<C-u>zz")

-- Functional wrapper for mapping custom keybindings
function map(mode, lhs, rhs, opts)
  local options = { noremap = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.api.nvim_set_keymap(
  "i",
  "<C-l>",
  "<cmd>lua require'luasnip'.expand_or_jump()<CR>",
  { noremap = true, silent = true }
)

-- map("n", "<Leader>n", ":NnnPicker<CR>")
map("n", "<Leader>nt", ":Neotree<CR>")
map("n", "<Leader>ns", ":Neotree document_symbols<CR>")

vim.keymap.set(
  "n",
  "<leader>tc",
  ":setlocal <C-R>=&conceallevel ? 'conceallevel=0' : 'conceallevel=2'<CR><CR>",
  { desc = "[T]oggle [C]onceallevel" }
)

map("n", "<Leader>ut", ":UndotreeToggle<CR>")

vim.keymap.set("n", "<Leader>um", "<cmd>colorscheme midnight<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>uM", "<cmd>colorscheme carbonfox<cr>", { noremap = true, silent = true })

vim.keymap.set({ "n" }, "<Leader>dc", "<cmd>DiffviewClose<cr>", { noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Leader>g.", "<cmd>Neogit<cr>", { noremap = true, silent = true })

-- Move visual selection up / down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Map `Q` to noop
vim.keymap.set("n", "Q", "<nop>")

-- Keeps cursor in place when using `J` -- the default
-- vim.keymap.set('n', 'J', "mzJ`z")

-- tmux-sessionizer
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Quickfix / Location List
vim.keymap.set("n", "gk", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "gj", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<Leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<Leader>j", "<cmd>lprev<CR>zz")

-- Make current file executable
vim.keymap.set("n", "<Leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true })

vim.keymap.set("n", "|", "%", { silent = true })

vim.keymap.set("n", "<Leader>cb", "<cmd>let @+ = fnamemodify(expand('%'), ':~:.')<cr>", { silent = true })

vim.keymap.set("n", "<Leader>gf", "<cmd>Telescope git_file_history<cr>", { silent = true })

vim.keymap.set("n", "<Leader>mt", "<cmd>Markview toggle<cr>", { silent = true })

-- Claude Code file:line references ---------------------------------------
-- `<leader>cy` copies a "path/to/file:line" (or "path:start-end") reference
-- to the clipboard, so it can be pasted into a Claude Code prompt.
-- `<leader>cY` sends that same reference straight into the tmux pane running
-- Claude Code via `tmux send-keys`, without pressing enter, so you can keep
-- typing a question before submitting.
--
-- Assumes exactly two panes in nvim's own tmux window: nvim's pane and
-- Claude Code's pane. The window is resolved explicitly from $TMUX_PANE
-- (nvim's own pane id), so this works the same in any number of tmux
-- sessions -- no naming/titling of panes or windows required.

local function claude_ref(start_line, end_line)
  local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
  if start_line == end_line then
    return string.format("%s:%d", path, start_line)
  end
  return string.format("%s:%d-%d", path, start_line, end_line)
end

local function find_claude_pane()
  local current = vim.env.TMUX_PANE
  if not current or current == "" then
    return nil
  end

  local window = vim.fn.system({ "tmux", "display-message", "-p", "-t", current, "#{window_id}" }):gsub("%s+$", "")
  if window == "" then
    return nil
  end

  local out = vim.fn.system({ "tmux", "list-panes", "-t", window, "-F", "#{pane_id}" })
  for id in out:gmatch("%S+") do
    if id ~= current then
      return id
    end
  end

  return nil
end

local function claude_copy(start_line, end_line)
  local ref = claude_ref(start_line, end_line)
  vim.fn.setreg("+", ref)
  vim.notify("Copied " .. ref)
end

local function claude_send(start_line, end_line)
  local ref = claude_ref(start_line, end_line)
  local target = find_claude_pane()
  if not target then
    vim.fn.setreg("+", ref)
    vim.notify("No Claude Code tmux pane found -- copied " .. ref .. " instead", vim.log.levels.WARN)
    return
  end
  vim.fn.system({ "tmux", "send-keys", "-t", target, "-l", ref .. " " })
end

vim.keymap.set("n", "<leader>cy", function()
  claude_copy(vim.fn.line("."), vim.fn.line("."))
end, { desc = "Copy file:line ref (Claude)" })

vim.keymap.set("x", "<leader>cy", function()
  claude_copy(math.min(vim.fn.line("v"), vim.fn.line(".")), math.max(vim.fn.line("v"), vim.fn.line(".")))
end, { desc = "Copy file:line-range ref (Claude)" })

vim.keymap.set("n", "<leader>cY", function()
  claude_send(vim.fn.line("."), vim.fn.line("."))
end, { desc = "Send file:line ref to Claude (tmux)" })

vim.keymap.set("x", "<leader>cY", function()
  claude_send(math.min(vim.fn.line("v"), vim.fn.line(".")), math.max(vim.fn.line("v"), vim.fn.line(".")))
end, { desc = "Send file:line-range ref to Claude (tmux)" })
