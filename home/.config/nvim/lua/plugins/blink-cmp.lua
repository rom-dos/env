return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      menu = {
        border = "single",
        draw = {
          padding = 4,
          components = {
            kind_icon = {
              text = function(ctx)
                return " " .. ctx.kind_icon .. ctx.icon_gap .. " "
              end,
            },
          },
        },
      },
      documentation = {
        window = { border = "single" },
      },
    },
    signature = { window = { border = "solid" } },
  },
  config = function(_, opts)
    require("blink.cmp").setup(opts)

    -- Carbonfox-themed highlight groups
    vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "#161616", fg = "#f2f4f8" })
    vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = "#161616", fg = "#525253" })
    vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { bg = "#25be6a", fg = "#161616" })
    vim.api.nvim_set_hl(0, "BlinkCmpScrollBarThumb", { bg = "#525253", fg = "NONE" })
    vim.api.nvim_set_hl(0, "BlinkCmpScrollBarGutter", { bg = "#2a2a2a", fg = "NONE" })

    -- Labels
    vim.api.nvim_set_hl(0, "BlinkCmpLabel", { fg = "#f2f4f8" })
    vim.api.nvim_set_hl(0, "BlinkCmpLabelDeprecated", { fg = "#525253", strikethrough = true })
    vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { fg = "#78A9FF", bold = true })
    vim.api.nvim_set_hl(0, "BlinkCmpLabelDetail", { fg = "#dfdfe0" })
    vim.api.nvim_set_hl(0, "BlinkCmpLabelDescription", { fg = "#a8b0c0" })

    -- Kind icons (colored by completion type)
    vim.api.nvim_set_hl(0, "BlinkCmpKind", { fg = "#78A9FF" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindText", { fg = "#f2f4f8" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindMethod", { fg = "#78A9FF" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindFunction", { fg = "#78A9FF" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindVariable", { fg = "#dfdfe0" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindKeyword", { fg = "#BE95FF" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindModule", { fg = "#33B1FF" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindClass", { fg = "#3DDBD9" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindInterface", { fg = "#3DDBD9" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindStruct", { fg = "#3DDBD9" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindEvent", { fg = "#FF7EB6" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindEnum", { fg = "#08BDBA" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindColor", { fg = "#3DDBD9" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindReference", { fg = "#EE5396" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindValue", { fg = "#25be6a" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindUnit", { fg = "#08BDBA" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindSnippet", { fg = "#FF7EB6" })
    vim.api.nvim_set_hl(0, "BlinkCmpKindConstant", { fg = "#3DDBD9" })
    -- Documentation
    vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "#161616", fg = "#f2f4f8" })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = "#161616", fg = "#525253" })
    vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { bg = "NONE", fg = "#525253" })
    vim.api.nvim_set_hl(0, "BlinkCmpDocCursorLine", { bg = "#282828", fg = "#f2f4f8" })

    -- Signature help
    vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", { bg = "#2a2a2a", fg = "#f2f4f8" })
    vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { bg = "#161616", fg = "#525253" })
    vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpActiveParameter", { fg = "#78A9FF", bold = true })

    -- Ghost text (preview)
    vim.api.nvim_set_hl(0, "BlinkCmpGhostText", { fg = "#525253" })
  end,
}
