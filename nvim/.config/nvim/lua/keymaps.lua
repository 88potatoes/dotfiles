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

-- Line navigation
vim.keymap.set('n', '<S-l>', '$', { desc = 'Go to end of line' })
vim.keymap.set('n', '<S-h>', '^', { desc = 'Go to start of line' })

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

-- Select whole buffer
map('n', '<D-a>', 'ggVG', { noremap = true, silent = true })
map('v', '<D-a>', '<Esc>ggVG<CR>==gi', { noremap = true, silent = true })

-- Diagnostics
map('n', '<leader>e', function() vim.diagnostic.open_float() end, { noremap = true, silent = true })

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

vim.keymap.set("n", "<leader>df", "<cmd>DiffviewFileHistory %<cr>", { desc = "[D]iff [F]ile History (Current File)" })
vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "[D]iff [C]lose" })
vim.keymap.set("n", "<leader>dm", "<cmd>DiffviewOpen main...HEAD<cr>", { desc = "Diff against merge-base of main" })
vim.keymap.set("n", "<leader>gy", function() Snacks.gitbrowse() end, { desc = "Git [Y]ank/Browse Link" })
vim.keymap.set("v", "<leader>gy", function() Snacks.gitbrowse() end, { desc = "Git Browse (Selection)" })
