-- (Modified) Bubbles config for lualine
-- (Original) Author: lokesh-krishna
-- MIT license, see LICENSE for more details.

local function wordcount()
  return tostring(vim.fn.wordcount().words) .. " words"
end

local function is_markdown()
  return vim.bo.filetype == "markdown" or vim.bo.filetype == "asciidoc"
end

-- stylua: ignore
local colors = {
  blue   = '#0e48c4',
  cyan   = '#79dac8',
  black  = '#080808',
  white  = '#c6c6c6',
  red    = '#ff5189',
  violet = '#6b7980',
  grey   = '#303030',
  yellow = '#fcba03',
  lavender  = '#b294bb',
}

local bubbles_theme = {
  normal = {
    a = { fg = colors.black, bg = colors.violet },
    b = { fg = colors.white, bg = colors.grey },
    c = { fg = colors.black, bg = colors.violet },
  },

  insert = { a = { fg = colors.black, bg = colors.yellow }, c = { fg = colors.black, bg = colors.yellow } },
  visual = { a = { fg = colors.black, bg = colors.cyan }, c = { fg = colors.black, bg = colors.cyan } },
  replace = { a = { fg = colors.black, bg = colors.red }, c = { fg = colors.black, bg = colors.red } },

  inactive = {
    a = { fg = colors.white, bg = colors.black },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.black, bg = colors.black },
  },
}

local config = {
  options = {
    theme = bubbles_theme,
    component_separators = "|",
    section_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = {
      { "mode", separator = { left = "", right = "" }, right_padding = 2 },
    },
    lualine_b = { "filename", "branch" },
    lualine_c = { "fileformat" },
    lualine_x = {
      { wordcount, cond = is_markdown },
      "encoding",
    },
    lualine_y = { "filetype", "progress" },
    lualine_z = {
      {
        function()
          return require("opencode").statusline()
        end,
      },
      { "location", separator = { right = "" }, left_padding = 2 },
    },
  },
  inactive_sections = {
    lualine_a = { "filename" },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = { "location" },
  },
  tabline = {},
  extensions = {},
}

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function()
    return config
  end,
}
