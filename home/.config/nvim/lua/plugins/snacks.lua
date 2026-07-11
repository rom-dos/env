return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    zen = {
      win = {
        height = 0.75,
        backdrop = {
          transparent = false,
          blend = 99,
        },
      },
    },
  },
}
