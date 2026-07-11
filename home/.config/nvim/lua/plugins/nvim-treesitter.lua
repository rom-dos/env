return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- ensure nvim-treesitter is always loaded as a start plugin:
    -- https://github.com/folke/lazy.nvim/blob/6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a/lua/lazy/core/loader.lua#L164
    lazy = false,
    -- after nvim-treesitter's path has been appended to lazy's in rtp, this ensures markview is loaded during startup
    -- and its path in turn is prepended to nvim-treesitter's:
    dependencies = { "OXY2DEV/markview.nvim" },
  },
  {
    "OXY2DEV/markview.nvim",
    -- Ensure markview is not handled explicitly by the start plugin logic:
    event = "VeryLazy", -- or lazy: true
  },
}
