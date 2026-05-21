local M = {}

M.setup = function()
  -- Siloed install:
  --   ~/.local/share/nvim/tsgo-native-preview
  -- Installed with:
  --   cd ~/.local/share/nvim/tsgo-native-preview
  --   npm install @typescript/native-preview@latest --save-exact
  -- Back to vtsls:
  --   NVIM_TYPESCRIPT_LSP=vtsls nvim
  local tsgo_cmd = vim.fn.expand("~/.local/share/nvim/tsgo-native-preview/node_modules/.bin/tsgo")

  if vim.fn.executable(tsgo_cmd) ~= 1 then
    vim.notify("tsgo not found: " .. tsgo_cmd, vim.log.levels.WARN)
    return
  end

  vim.lsp.config("tsgo", {
    cmd = { tsgo_cmd, "--lsp", "--stdio" },
    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    },
    root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  })

  vim.lsp.enable("tsgo")
end

return M
