local vaultName = vim.env.NVIM_OBSD_VAULT_NAME
local vaultPath = vim.env.NVIM_OBSD_VAULT_PATH
local vaultNameWork = vim.env.NVIM_OBSD_VAULT_NAME_WORK
local vaultPathWork = vim.env.NVIM_OBSD_VAULT_PATH_WORK

if not (vaultName and vaultPath and vaultNameWork and vaultPathWork) then
  return {}
end

return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = (os.getenv("SYSTEM") == "work") and vaultNameWork or vaultName,
          path = (os.getenv("SYSTEM") == "work") and vaultPathWork or vaultPath,
        },
      },
      notes_subdir = "-buffer",
      daily_notes = {
        folder = "-days",
        date_format = "%d%m%y",
        alias_format = "%B %-d, %Y",
        template = "_templates/daily-template.md",
      },
      templates = {
        folder = "_templates",
        date_format = "%d%m%y",
        time_format = "%H%M%S",
      },
      ui = {
        enable = false,
      },
      -- Optional, configure key mappings.
      mappings = {
        -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
        ["gf"] = {
          action = "ObsidianFollowLink",
          desc = "Follow link",
        },
        -- Toggle check-boxes.
        ["<leader>ch"] = {
          action = "ObsidianToggleCheckbox",
          desc = "Toggle checkbox",
        },
        -- Insert/modify tags.
        ["<leader>at"] = {
          action = "ObsidianTemplate",
          desc = "Insert template",
        },
      },
      -- Optional, configure attachments for new notes.
      attachments = {
        folder = "assets/imgs",
        img_text_func = function(...)
          return require("obsidian.builtin").img_text_func(...)
        end,
      },
      -- Optional, configure search.
      search = {
        -- Optional, sort search results by "path", "modified", "accessed", or "created".
        sort_by = "modified",
        sort_reversed = true,
        max_lines = 1000,
      },
      -- Optional, by default when you use `:ObsidianFollowLink` on a file://
      -- link it will 1. display a list of notes sorted by last modified and
      -- 2. prompt you to select one to open using `vim.ui.select`.
      -- Setting this to true will skip step 1 and always just prompt you to
      -- select a note.
      follow_url_func = function(url)
        if #url == 0 then
          print("No URL provided")
          return
        end
        -- Open the URL in the browser.
        vim.fn.jobstart({ "open", url }, { on_exit = function() end })
      end,
      frontmatter = {
        enabled = true,
      },
    },
    cmd = {
      "ObsidianInit",
      "ObsidianNew",
      "ObsidianNewFromTemplate",
      "ObsidianSearch",
      "ObsidianQuickSwitch",
      "ObsidianFollowLink",
      "ObsidianToggleCheckbox",
      "ObsidianTemplate",
      "ObsidianPasteImg",
      "ObsidianToday",
      "ObsidianYesterday",
      "ObsidianTomorrow",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
