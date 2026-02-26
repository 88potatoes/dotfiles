-- Key mappings
local map = vim.keymap.set
local api = vim.api

-- Save commands
api.nvim_set_keymap('i', '<D-s>', '<C-c>:w<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('n', '<D-s>', ':w<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('i', '<C-s>', '<C-c>:w<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('n', '<C-s>', ':w<CR>', { noremap = true, silent = true })

-- LSP and formatting
api.nvim_set_keymap('i', '<D-o>', '<Cmd>lua vim.lsp.buf.format()<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('n', '<D-o>', '<Cmd>lua vim.lsp.buf.format()<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('n', '<D-.>', '<Cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('v', '<D-.>', '<Cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('n', '<leader>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })

-- Navigation
api.nvim_set_keymap('n', '<S-l>', '<C-o>$', { noremap = true, silent = true })
api.nvim_set_keymap('n', '<S-j>', '<C-o>^', { noremap = true, silent = true })

-- Grep
-- api.nvim_set_keymap('n', '<leader>gw', 'viwy/<C-r>"<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gW', function()
  Snacks.picker.lsp_references({
    filter = {
      exclude = {
        "**/__tests__/**",
        "**/*.test.*",
        "**/*.spec.*",
        "**/coverage/**",
        "**/tests/**",
        "**/test_*.py",
        "**/*_test.py",
      }
    }
  })
end, { noremap = true, silent = true, desc = 'LSP: Find references (exclude tests)' })

-- Move lines up/down
-- Normal mode
map('n', '<C-j>', ':m .+1<CR>==', { noremap = true, silent = true })
map('n', '<C-k>', ':m .-2<CR>==', { noremap = true, silent = true })
map('i', '<C-j>', '<Esc>:m .+1<CR>==gi', { noremap = true, silent = true })
map('i', '<C-k>', '<Esc>:m .-2<CR>==gi', { noremap = true, silent = true })
map('v', '<C-j>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
map('v', '<C-k>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- Diagnostics
map('n', '<leader>e', function() vim.diagnostic.open_float() end, { noremap = true, silent = true })

-- Alt+Backspace to delete word in insert mode
map('i', '<A-BS>', '<C-w>')

-- Find text
map("n", "<A-f>", "viwy /<D-v>", { noremap = true, silent = true })

-- Snacks
vim.keymap.set("n", "<leader>pf", function() Snacks.picker.files() end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Grep" })
vim.keymap.set("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })

-- LazyGit
map('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = "LazyGit" })

-- Undotree
map('n', '<leader>u', '<cmd>UndotreeToggle<cr>', { desc = "LazyGit" })

-- Supermaven Completion
api.nvim_set_keymap('i', '<C-Tab>', [[<Cmd>lua require('supermaven').expand()<CR>]], { silent = true, noremap = true })

-- LSP keymaps
map('n', 'gd', vim.lsp.buf.definition, {})
map('n', 'K', vim.lsp.buf.hover, {})
map('n', '<leader>rn', vim.lsp.buf.rename, {})

vim.keymap.set('n', '<leader>]', '<C-i>', { desc = 'Jump List Forward' })
vim.keymap.set('n', '<leader>[', '<C-o>', { desc = 'Jump List Backward' })

vim.keymap.set('n', '<leader>we', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })

vim.keymap.set('n', '<leader>cc', function()
  local path = vim.fn.expand('%:.')
  vim.fn.setreg('+', path)
  print('Copied to clipboard: ' .. path)
end, { desc = 'Copy file path from cwd' })

vim.fn.setreg('s', 'F(wyiwysiw{f:a{pa:f)i}')

vim.keymap.set('n', '<A-Up>', ':resize +2<CR>')
vim.keymap.set('n', '<A-Down>', ':resize -2<CR>')
vim.keymap.set('n', '<A-Left>', ':vertical resize -2<CR>')
vim.keymap.set('n', '<A-Right>', ':vertical resize +2<CR>')

-- Fyler
vim.keymap.set("n", "<leader>ly", function() require('fyler').open() end, { desc = "Fyler [E]xplorer" })



