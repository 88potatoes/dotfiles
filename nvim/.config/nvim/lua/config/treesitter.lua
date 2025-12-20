-- Treesitter Configuration
require('nvim-treesitter.configs').setup({
  auto_install = true,
  indent = { enable = true },
  ensure_installed = {
    -- defaults
    "vim",
    "lua",
    "vimdoc",

    -- web dev
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "astro",
    "vue",
    "svelte",
    "markdown",
    "markdown_inline",
    "json",
    "scss",
    "yaml",
    "prisma"
  },
  autotag = {
    enable = true,
    filetypes = {
      'html', 'javascript', 'typescript', 'svelte', 'vue', 'tsx', 'jsx',
      'prisma', 'rescript', 'css', 'lua', 'xml', 'php', 'markdown', 'typescriptreact'
    },
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = false

  }
})
