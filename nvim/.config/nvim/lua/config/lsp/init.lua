local M = {}

M.setup = function()
  require("mason").setup()

  require('config.lsp.lua_ls').setup()
  require('config.lsp.pyright').setup()

  local typescript_lsp = vim.env.NVIM_TYPESCRIPT_LSP or "tsgo"
  if typescript_lsp == "vtsls" then
    require('config.lsp.vtsls').setup()
  elseif typescript_lsp == "tsgo" then
    require('config.lsp.tsgo').setup()
  else
    vim.notify("Unknown NVIM_TYPESCRIPT_LSP: " .. typescript_lsp, vim.log.levels.WARN)
  end
end

return M
