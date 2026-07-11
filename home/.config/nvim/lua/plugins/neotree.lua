return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    -- {
    --   "<leader>e",
    --   function()
    --     require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
    --   end,
    --   desc = "Explorer NeoTree (cwd)",
    -- },
    -- {
    --   "<leader>E",
    --   function()
    --     require("neo-tree.command").execute({ toggle = true, dir = vim.fn.expand("%:p:h") })
    --   end,
    --   desc = "Explorer NeoTree (current file)",
    -- },
    {
      "<leader>o",
      function()
        local filetype = vim.bo.filetype
        if filetype == "markdown" then
          require("neo-tree.command").execute({ source = "document_symbols", toggle = true })
        else
          require("neo-tree.command").execute({ source = "document_symbols", toggle = true })
        end
      end,
      desc = "Symbols/Headings Outline",
    },
  },
  deactivate = function()
    vim.cmd([[Neotree close]])
  end,
  init = function()
    if vim.fn.argc(-1) == 1 then
      local stat = vim.loop.fs_stat(vim.fn.argv(0))
      if stat and stat.type == "directory" then
        require("neo-tree")
      end
    end
  end,
  opts = {
    sources = { "filesystem", "buffers", "git_status", "document_symbols" },
    open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = {
        enabled = true,
      },
      cwd_target = "buffer",
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false,
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_hidden = false,
      },
    },
    document_symbols = {
      follow_cursor = true,
      client_filters = "first",
      renderers = {
        symbol = {
          { "indent", with_expanders = true },
          { "kind_icon", default = "?" },
          {
            "name",
            highlight = "NeoTreeSymbolName",
          },
        },
      },
    },
    window = {
      position = "float",
      width = 40,
      popup = {
        position = { col = "3%", row = "4" },
        size = {
          height = "80%",
          width = "40",
        },
        border = {
          style = "rounded",
          text = {
            top = " ☻  ",
            top_align = "center",
          },
        },
      },
      mapping_options = {
        noremap = true,
        nowait = true,
      },
      mappings = {
        ["<space>"] = "none",
        ["Y"] = {
          function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path, "c")
          end,
          desc = "Copy Path to Clipboard",
        },
        ["O"] = {
          function(state)
            require("lazy.util").open(state.tree:get_node().path, { system = true })
          end,
          desc = "Open with System Application",
        },
        ["P"] = {
          "toggle_preview",
          config = {
            use_float = true,
            use_image_nvim = false,
          },
        },
        ["l"] = "open",
        ["h"] = "close_node",
        ["<M-]>"] = { "scroll_preview", config = { direction = -10 } },
        ["<M-[>"] = { "scroll_preview", config = { direction = 10 } },
      },
    },
    default_component_configs = {
      indent = {
        with_expanders = true,
        expander_collapsed = "",
        expander_expanded = "",
        expander_highlight = "NeoTreeExpander",
      },
      git_status = {
        symbols = {
          added = "",
          modified = "",
          deleted = "✖",
          renamed = "󰁕",
          untracked = "",
          ignored = "",
          unstaged = "󰄱",
          staged = "",
          conflict = "",
        },
      },
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
    vim.api.nvim_create_autocmd("TermClose", {
      pattern = "*lazygit",
      callback = function()
        if package.loaded["neo-tree.sources.manager"] then
          require("neo-tree.sources.manager").refresh("filesystem")
        end
      end,
    })
  end,
}
