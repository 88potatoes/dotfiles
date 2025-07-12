-- Telescope configuration
local telescope = require('telescope')

telescope.load_extension('file_browser')

telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<M-BS>"] = function()
          vim.api.nvim_input("<C-w>") -- Ctrl-w is the default vim command to delete a word backward
        end,
        ["<D-BS>"] = function()
          vim.api.nvim_input("dd")
        end
      }
    }
  },
  extensions = {
    file_browser = {
      theme = "ivy",
      hijack_netrw = true,
    },
  }
})

return telescope
