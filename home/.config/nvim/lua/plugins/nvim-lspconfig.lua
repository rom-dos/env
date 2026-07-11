local renoise_lua_path = vim.fn.expand("~/workspace/source/_vendor/renoise-lua-definitions/")

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            workspace = {
              library = { renoise_lua_path },
            },
            runtime = {
              plugin = { renoise_lua_path .. "plugin.lua" },
            },
          },
        },
      },
      jsonls = {
        filetypes = { "json", "jsonc" },
        settings = {
          json = {
            schemas = require("schemastore").json.schemas({
              select = {
                "babelrc.json",
                ".eslintrc",
                "lerna.json",
                "package.json",
                "prettierrc.json",
                "Stylelint (.stylelintrc)",
                "tsconfig.json",
              },
            }),
            validate = { enable = true },
          },
        },
      },
    },
  },
}
