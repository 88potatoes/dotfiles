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
  }
})
