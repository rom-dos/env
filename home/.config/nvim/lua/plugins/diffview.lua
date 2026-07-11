return {
  "sindrets/diffview.nvim",
  config = function()
    local actions = require("diffview.actions")

    require("diffview").setup({
      keymaps = {
        view = {
          { "n", "<M-]>", actions.scroll_view(-0.25), { desc = "Scroll the view up" } },
          { "n", "<M-[>", actions.scroll_view(0.25), { desc = "Scroll the view down" } },
        },
      },
    })
  end,
}
