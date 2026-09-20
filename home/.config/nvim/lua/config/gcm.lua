local M = {}

local commit_types = {
  "feat",
  "fix",
  "build",
  "chore",
  "ci",
  "docs",
  "style",
  "refactor",
  "perf",
  "test",
}

local function trim(value)
  return (value or ""):gsub("%s+$", "")
end

local function git(root, args)
  local command = { "git", "-C", root }
  vim.list_extend(command, args)
  return vim.system(command, { text = true }):wait()
end

local function git_root()
  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, {
    cwd = vim.fn.getcwd(),
    text = true,
  }):wait()

  if result.code ~= 0 then
    return nil, trim(result.stderr) ~= "" and trim(result.stderr) or "Not inside a Git repository"
  end

  return trim(result.stdout)
end

local function branch_scope(root)
  local result = git(root, { "symbolic-ref", "--quiet", "--short", "HEAD" })
  if result.code ~= 0 then
    return "0"
  end

  local branch = trim(result.stdout)
  return branch:match("^[^/]+/[^/]+/([A-Z][A-Z0-9]*%-%d+)%-")
    or branch:match("^[^/]+/[^/]+/([A-Z][A-Z0-9]*%-%d+)$")
    or "0"
end

local function refresh_neogit()
  pcall(function()
    require("neogit").refresh()
  end)
end

local function open_commit_buffer(root, commit_type)
  local prefix = string.format("%s(%s): ", commit_type, branch_scope(root))

  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "gcm://COMMIT_EDITMSG/" .. buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prefix })

  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "gitcommit"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modified = true

  local committed = false
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      if committed then
        vim.bo[buf].modified = false
        return
      end

      local message = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
      local result = vim.system({ "git", "-C", root, "commit", "--file=-" }, {
        stdin = message,
        text = true,
      }):wait()

      if result.code ~= 0 then
        local error_message = trim(result.stderr)
        if error_message == "" then
          error_message = trim(result.stdout)
        end
        error("gcm: " .. (error_message ~= "" and error_message or "git commit failed"), 0)
      end

      committed = true
      vim.bo[buf].modified = false
      refresh_neogit()
      vim.notify("Commit created", vim.log.levels.INFO, { title = "gcm" })
    end,
  })

  vim.api.nvim_win_set_cursor(0, { 1, #prefix })
  vim.cmd("startinsert!")
end

function M.commit()
  local root, err = git_root()
  if not root then
    vim.notify(err, vim.log.levels.ERROR, { title = "gcm" })
    return
  end

  vim.ui.select(commit_types, { prompt = "Commit type:" }, function(commit_type)
    if commit_type then
      open_commit_buffer(root, commit_type)
    end
  end)
end

return M
