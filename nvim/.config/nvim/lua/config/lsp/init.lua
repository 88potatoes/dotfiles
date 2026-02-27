local M = {}

M.setup = function()
  require("mason").setup()

  require('config.lsp.lua_ls').setup()
  require('config.lsp.pyright').setup()
  require('config.lsp.vtsls').setup()
end

return M
