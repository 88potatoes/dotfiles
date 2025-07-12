-- In lua/config/nvim-ts-autotag.lua
require("nvim-ts-autotag").setup({
  enable = true,
  filetypes = {
    'html', 'javascript', 'typescript', 'svelte', 'vue', 'tsx', 'jsx',
    'prisma', 'rescript', 'css', 'lua', 'xml', 'php', 'markdown', 'typescriptreact'
  },
  enable_close = true,
  enable_rename = true,
  enable_close_on_slash = false
})
