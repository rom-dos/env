local GITHUB_USER_NAME = vim.env.GITHUB_USER_NAME

if not GITHUB_USER_NAME then
  return {}
end

local mappings = require("telescope.mappings")

return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  opts = {
    picker = "telescope",
    enable_builtin = true,
    mappings = {
      notification = {
        read = { lhs = "<localleader>nr", desc = "mark notification as read" },
        done = { lhs = "<localleader>nd", desc = "mark notification as done" },
        unsubscribe = { lhs = "<localleader>nu", desc = "unsubscribe from notifications" },
      },
    },
  },
  keys = {
    {
      "<leader>oi",
      "<CMD>Octo issue list<CR>",
      desc = "List GitHub Issues",
    },
    -- {
    --   "<leader>op",
    --   "<CMD>Octo pr list<CR>",
    --   desc = "List GitHub PullRequests",
    -- },
    {
      "<leader>op",
      function()
        local repo_name = require("octo.utils").get_remote_name()
        local prompt = string.format("is:pr state:open author:%s %s", GITHUB_USER_NAME, repo_name)

        require("octo.pickers.telescope.provider").search({
          prompt = prompt,
        })
      end,
      desc = "List (My) GitHub PullRequests",
    },
    {
      "<leader>od",
      "<CMD>Octo discussion list<CR>",
      desc = "List GitHub Discussions",
    },
    {
      "<leader>on",
      "<CMD>Octo notification list<CR>",
      desc = "List GitHub Notifications",
    },
    {
      "<leader>os",
      function()
        require("octo.utils").create_base_search_command({ include_current_repo = true })
      end,
      desc = "Search GitHub",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
}
