-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local view_group = augroup("auto_view", { clear = true })

autocmd({ "BufWinLeave", "BufWritePost", "WinLeave" }, {
  desc = "Save view with mkview for real files",
  group = view_group,
  callback = function(args)
    local buf = args.buf
    if vim.b[buf].view_activated then
      pcall(vim.cmd, "silent! mkview")
    end
  end,
})

autocmd("BufWinEnter", {
  desc = "Try to load file view if available and enable view saving for real files",
  group = view_group,
  callback = function(args)
    local buf = args.buf
    if not vim.b[buf].view_activated then
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
      local ignore_filetypes = { "gitcommit", "gitrebase", "svg", "hgcommit" }
      if buftype == "" and filetype and filetype ~= "" and not vim.tbl_contains(ignore_filetypes, filetype) then
        vim.b[buf].view_activated = true
        pcall(vim.cmd, "silent! loadview")
      end
    end
  end,
})
