-- Save file
vim.keymap.set({ 'n', 'i' }, '<D-s>', '<cmd>w<cr><Esc>', { desc = 'Save file' })

-- Formatting
vim.keymap.set({ 'n', 'i' }, '<D-o>', vim.lsp.buf.format, { desc = 'LSP: Format buffer' })

-- Code Action
vim.keymap.set({ 'n', 'v' }, '<D-.>', vim.lsp.buf.code_action, { desc = 'LSP: Code action' })

-- Send visual selection to previous Zellij pane
vim.keymap.set('v', '<leader>ap', function()
  require('zellij_mru').send_visual({
    script = vim.fn.expand('~/.local/bin/zellij-mru-send'),
    enter = false,
  })
end, { desc = 'Paste selection to previous zellij pane' })

-- Grep
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

-- Delete to start of word
vim.keymap.set('i', '<A-BS>', '<C-w>', { desc = 'Delete word backward' })
vim.keymap.set('n', '<A-BS>', 'db', { desc = 'Delete to start of word' })

-- Move lines up/down
-- Normal mode
vim.keymap.set('n', '<C-j>', ':m .+1<CR>==', { noremap = true, silent = true })
vim.keymap.set('n', '<C-k>', ':m .-2<CR>==', { noremap = true, silent = true })
vim.keymap.set('i', '<C-j>', '<Esc>:m .+1<CR>==gi', { noremap = true, silent = true })
vim.keymap.set('i', '<C-k>', '<Esc>:m .-2<CR>==gi', { noremap = true, silent = true })
vim.keymap.set('v', '<C-j>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set('v', '<C-k>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- Select whole buffer
vim.keymap.set('n', '<D-a>', 'ggVG', { noremap = true, silent = true })
vim.keymap.set('v', '<D-a>', '<Esc>ggVG<CR>==gi', { noremap = true, silent = true })

-- Diagnostics
vim.keymap.set("n", "<leader>e", function()
  -- Get all diagnostics for the current line
  local line_num = vim.fn.line(".") - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line_num })

  if #diagnostics > 0 then
    local messages = {}
    for _, diag in ipairs(diagnostics) do
      -- Clean up the message (optional: remove trailing/leading whitespace)
      table.insert(messages, diag.message)
    end

    -- Join them with a newline for better readability when pasting
    local full_message = table.concat(messages, "\n")

    vim.fn.setreg("+", full_message)
    print("Yanked " .. #diagnostics .. " diagnostics to clipboard!")
  else
    print("No diagnostics found on this line.")
  end
end, { desc = "Yank all line diagnostics to clipboard" })

-- Snacks
vim.keymap.set("n", "<leader>ff", function()
  Snacks.picker.files({
    hidden = true,
  })
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fj", function()
  Snacks.picker.grep({
    hidden = true
  })
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fs", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols" })

-- LazyGit
vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = "LazyGit" })

-- Undotree
vim.keymap.set('n', '<leader>u', '<cmd>UndotreeToggle<cr>', { desc = "LazyGit" })

-- Supermaven Completion
vim.keymap.set('i', '<C-Tab>', function()
  require('supermaven').expand()
end, { silent = true, desc = "Supermaven Expand" })


-- LSP keymaps
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})

vim.keymap.set('n', '<S-h>', '<C-o>', { desc = 'Jump List Backward' })
vim.keymap.set('n', '<S-l>', '<C-i>', { desc = 'Jump List Forward' })

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

vim.keymap.set("n", "<leader>df", "<cmd>DiffviewFileHistory %<cr>", { desc = "[D]iff [F]ile History (Current File)" })
vim.keymap.set("n", "<leader>dc", function()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok or not lib.get_current_view() then
    return
  end

  local target_tab = lib.get_prev_non_view_tabpage()
  if target_tab then
    vim.api.nvim_set_current_tabpage(target_tab)
  else
    vim.notify("No non-Diffview tab to switch to", vim.log.levels.WARN)
  end
end, { desc = "[D]iff Hide ([C]ollapse)" })
vim.keymap.set("n", "<leader>dx", "<cmd>DiffviewClose<cr>", { desc = "[D]iff Close" })
vim.keymap.set("n", "<leader>dm", function()
  local diff_args = { "main...HEAD" }
  local ok, lib = pcall(require, "diffview.lib")

  if ok then
    for _, view in ipairs(lib.views or {}) do
      if view.rev_arg == "main...HEAD" and view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
        local selected_file = view.panel and view.panel.cur_file and view.panel.cur_file.path
        local panel_focused = view.panel and view.panel.is_focused and view.panel:is_focused()

        view:close()
        lib.dispose_view(view)

        if selected_file then
          vim.list_extend(diff_args, { "--selected-file", selected_file })
        end

        require("diffview").open(diff_args)

        if not panel_focused then
          vim.defer_fn(function()
            local wins = vim.api.nvim_tabpage_list_wins(0)
            for _, win in ipairs(wins) do
              local bufnr = vim.api.nvim_win_get_buf(win)
              local ft = vim.bo[bufnr].filetype
              if ft ~= "DiffviewFiles" and ft ~= "DiffviewFileHistory" then
                vim.api.nvim_set_current_win(win)
                return
              end
            end
          end, 100)
        end

        return
      end
    end
  end

  vim.cmd("DiffviewOpen main...HEAD")
end, { desc = "Diff against merge-base of main" })
vim.keymap.set("n", "<leader>gy", function() Snacks.gitbrowse() end, { desc = "Git [Y]ank/Browse Link" })
vim.keymap.set("v", "<leader>gy", function() Snacks.gitbrowse() end, { desc = "Git Browse (Selection)" })

vim.keymap.set('n', '<leader>u', function() Snacks.picker.undo() end, { desc = "Undotree Toggle" })

vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>")
vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>")
vim.keymap.set({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>")
vim.keymap.set({ "n", "o", "x" }, "ge", "<cmd>lua require('spider').motion('ge')<CR>")

-- Find and open .env file by searching up directory tree
vim.keymap.set('n', '<leader>le', function()
  local current = vim.fn.expand('%:p:h')
  while current ~= '/' do
    local env_path = current .. '/.env'
    if vim.fn.filereadable(env_path) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(env_path))
      return
    end
    current = vim.fn.fnamemodify(current, ':h')
  end
  print('No .env found')
end, { desc = 'Open .env (search up tree)' })
