return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-telescope/telescope-ui-select.nvim", "isak102/telescope-git-file-history.nvim" },
  config = function()
    require("config.telescope")()
    require("telescope").load_extension("git_file_history")
  end,
}
