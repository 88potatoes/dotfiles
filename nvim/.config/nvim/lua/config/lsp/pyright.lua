local M = {}

M.setup = function()
  local pyright_config = {
    cmd = { "pyright-langserver", "--stdio" },
    root_markers = {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
      "Pipfile",
      "pyrightconfig.json",
      ".git"
    },

    settings = {
      python = {
        analysis = {
          -- There's the notion of 'Type Checking Severity'
          -- Options: "off", "basic", "strict"
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          -- This singular setting helps with auto-imports
          indexing = true,
        },
      },
    },
  }

  vim.lsp.config('pyright', pyright_config)
  vim.lsp.enable('pyright')
end

return M
