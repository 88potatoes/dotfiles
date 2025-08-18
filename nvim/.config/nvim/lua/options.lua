-- Vim options and settings

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Disable netrw (since you're using nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24-bit color
vim.opt.termguicolors = true

-- Register language handlers
vim.treesitter.language.register('tsx', 'typescriptreact')
vim.treesitter.language.register('prisma', 'prisma')

-- Set dashboard as the startup screen
vim.g.dashboard_default_executive = "telescope"
vim.g.dashboard_disable_statusline = 1
vim.g.dashboard_disable_at_vimenter = 0
