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

local function get_grep_args()
  return {
    -- 1. Standard Exclusions (Tests)
    "--glob", "!**/__tests__/**",
    "--glob", "!**/*.test.*",
    "--glob", "!**/*.spec.*",
    "--glob", "!**/*.spec.*",
    "--glob", "!**/coverage/**",
    "--glob", "!**tests/**",

    -- 4. Pytest Exclusions (Standard Python patterns)
    "--glob", "!**/test_*.py",  -- Excludes test_main.py
    "--glob", "!**/*_test.py",  -- Excludes main_test.py
  }
end

local function get_find_command()
  local command = { "rg", "--files" }
  local args = get_grep_args()
  -- Append your shared args to the command list
  for _, v in ipairs(args) do
    table.insert(command, v)
  end
  return command
end

-- Grep
api.nvim_set_keymap('n', '<leader>gw', 'viwy/<C-r>"<CR>', { noremap = true, silent = true })
map('n', '<leader>gW', function()
  require('telescope.builtin').lsp_references({
    file_ignore_patterns = {
      "**/__tests__/**",
      "**/*.test.*",
      "**/*.spec.*",
      "**/coverage/**",
      "**tests/**",
      "**/test_*.py",
      "**/*_test.py",
    }
  })
end, { noremap = true, silent = true, desc = 'LSP: Find references (exclude tests)' })

-- Move lines up/down
-- Normal mode
map('n', '<C-j>', ':m .+1<CR>==', { noremap = true, silent = true })
map('n', '<C-k>', ':m .-2<CR>==', { noremap = true, silent = true })
-- Insert mode
map('i', '<C-j>', '<Esc>:m .+1<CR>==gi', { noremap = true, silent = true })
map('i', '<C-k>', '<Esc>:m .-2<CR>==gi', { noremap = true, silent = true })

-- Visual mode
map('v', '<C-j>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
map('v', '<C-k>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- Buffer management
map('n', '<D-S-w>', function()
  local current_buf = vim.api.nvim_get_current_buf()
  vim.cmd('bdelete ' .. current_buf)
end, { noremap = true, silent = true })

-- Select whole file
map('n', '<D-a>', '<esc>gg0vGg_', { noremap = true, silent = true })

-- Buffer navigation
map('n', '<S-l>', ':bnext<CR>', { noremap = true, silent = true })
map('n', '<S-h>', ':bprevious<CR>', { noremap = true, silent = true })

-- Diagnostics
map('n', '<leader>e', function() vim.diagnostic.open_float() end, { noremap = true, silent = true })

-- Insert blank line in normal mode
map('n', '<D-Space>', 'o<Esc>', { noremap = true, silent = true })

-- Alt+Backspace to delete word in insert mode
map('i', '<A-BS>', '<C-w>')

-- Find text
map("n", "<A-f>", "viwy /<D-v>", { noremap = true, silent = true })

-- Close buffer
map('n', '<leader>x', '<Cmd>bdelete<CR>', { noremap = true, silent = true })
map('n', '<leader>bd', '<Cmd>bdelete<CR>', { noremap = true, silent = true })

-- Telescope
map("n", "<leader>pv", vim.cmd.Ex)
map('n', '<leader>pf', function()
  require('telescope.builtin').find_files({
    prompt_title = "Find Files (exclude testfiles)",
    find_command = get_find_command()
  })
end, {})
map('n', '<leader>pF', function()
  require('telescope.builtin').find_files({
    prompt_title = "Find Files (all files)",
  })
end, {})
map('n', '<leader>fg', function()
  require('telescope.builtin').live_grep({
    prompt_title = "Grep (exclude testfiles)",
    additional_args = get_grep_args,
  })
end, {})
map('n', '<leader>fG', function()
  require('telescope.builtin').live_grep({
    prompt_title = "Grep (all files)",
  })
end, {})
map('n', '<leader>fh', function()
  local buffer_dir = vim.fn.expand('%:p:h')
  if buffer_dir == "" or buffer_dir == "." then
    buffer_dir = vim.fn.getcwd()
  end

  local dir_name = vim.fn.fnamemodify(buffer_dir, ':t')
  require('telescope.builtin').live_grep({
    cwd = buffer_dir,
    prompt_title = "Grep in: " .. dir_name,
  })
end, {})
map('n', '<leader>fd', function() require('telescope.builtin').diagnostics({ bufnr = 0, severity_bound = 0 }) end, {})
map('n', '<leader>fb', function() require('telescope.builtin').buffers({ sort_lastused = true }) end,
  { desc = 'List buffers' })

-- LazyGit
map('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = "LazyGit" })

-- Undotree
map('n', '<leader>u', '<cmd>UndotreeToggle<cr>', { desc = "LazyGit" })

-- Todoist
map("n", "<leader>td", ":Todoist<CR>", { desc = "Open Todoist" })

-- Flash
map({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
map({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
map("o", "r", function() require("flash").remote() end, { desc = "Remote Flash" })
map({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
map("c", "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })

-- Supermaven Completion
api.nvim_set_keymap('i', '<C-Tab>', [[<Cmd>lua require('supermaven').expand()<CR>]], { silent = true, noremap = true })

-- LSP keymaps
map('n', 'gd', vim.lsp.buf.definition, {})
map('n', 'K', vim.lsp.buf.hover, {})
map('n', '<leader>rn', vim.lsp.buf.rename, {})

-- NvimTree
map('n', '<leader>lt', ':NvimTreeToggle<CR>', { desc = 'Toggle NvimTree' })

-- Harpoon
local harpoon = require("harpoon")
vim.keymap.set("n", "<leader>pbn", function() harpoon:list():add() end)
vim.keymap.set("n", "<leader>pbl", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<leader>pba", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<leader>pbs", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<leader>pbd", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<leader>pbf", function() harpoon:list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)

-- In your keymaps.lua file
vim.keymap.set("n", "<leader>S", "<cmd>lua require('spectre').toggle()<CR>", { desc = "Toggle Spectre" })
vim.keymap.set("n", "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word=true})<CR>",
  { desc = "Search current word" })
vim.keymap.set("n", "<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word=true})<CR>",
  { desc = "Search on current file" })

-- Move buffer position
map('n', '<leader>bl', '<Cmd>BufferLineMoveNext<CR>', { noremap = true, silent = true })
map('n', '<leader>bh', '<Cmd>BufferLineMovePrev<CR>', { noremap = true, silent = true })

-- local my_plugin = require('plugin.buffer-tree')
-- vim.keymap.set("n", "<leader>bb", my_plugin.open_buffer, { desc = "Open buffer" })

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
