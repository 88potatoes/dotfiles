local M = {}

M.setup = function()
  local vtsls_config = {
    cmd = { "vtsls", "--stdio" },
    root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
    settings = {
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        inlayHints = {
          parameterNames = { enabled = "all" },
          variableTypes = { enabled = true },
        },
      },
      javascript = {
        updateImportsOnFileMove = { enabled = "always" },
      },
      vtsls = {
        -- This singular setting enables the specialized vtsls features
        autoUseWorkspaceTsdk = true,
        experimental = {
          completion = {
            enableServerSideFuzzyMatch = true,
          },
        },
      },
    },
  }

  vim.lsp.config('vtsls', vtsls_config)
  vim.lsp.enable('vtsls')
end

return M
