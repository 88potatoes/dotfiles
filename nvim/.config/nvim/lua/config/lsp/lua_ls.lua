local M = {}

M.setup = function()
  local lua_ls = {
    settings = {
      Lua = {
        telemetry = { enable = false },
        -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
        diagnostics = {
          disable = { 'missing-fields' },
          globals = { "vim", "Snacks" }
        },
        hint = { enable = true },
        workspace = {
          checkThirdParty = false,
        }

      },
    }
  }

  vim.lsp.config('lua_ls', lua_ls)
  vim.lsp.enable('lua_ls')
end

return M
