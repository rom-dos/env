return function()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local function copy_git_hash(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local short_hash = string.sub(selection.value or "", 1, 7)
    actions.close(prompt_bufnr)
    vim.fn.setreg("+", short_hash)
    vim.fn.setreg("*", short_hash)
    vim.notify("Copied commit hash: " .. short_hash)
  end

  require("telescope").setup({
    extensions = {
      ["ui-select"] = {
        require("telescope.themes").get_dropdown({}),
      },
    },
    defaults = {
      path_display = { truncate = 3 },
    },
  })

  require("telescope").load_extension("ui-select")
  require("telescope").load_extension("git_file_history")

  local gfh_config = require("telescope._extensions.git_file_history.config")
  gfh_config.values.mappings.i["<CR>"] = copy_git_hash
  gfh_config.values.mappings.n["<CR>"] = copy_git_hash
end
