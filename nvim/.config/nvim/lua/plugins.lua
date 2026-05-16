-- Plugin setup with lazy.nvim

-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

-- Set up plugins
require("lazy").setup({
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
    },
  },
  {
    "mikavilpas/yazi.nvim",
    dependencies = {
      "folke/snacks.nvim"
    },
    keys = {
      {
        "<leader>ll",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
    },
    opts = {
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
    },
    init = function()
      vim.g.loaded_netrwPlugin = 1
    end,
  },
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
  },
  {
    'saghen/blink.cmp',
    version = "v1.9.0",
    opts = {
      keymap = {
        preset = 'none', -- The Notion of a Clean Slate
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' }, -- CR is the 'Enter' key
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      completion = {
        menu = { border = 'rounded' },
        documentation = { window = { border = 'rounded' }, auto_show = true },
      },
    },
  },
  -- Mason
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate", -- :MasonUpdate updates registry contents
    config = function()
      require("config.lsp.init").setup()
    end,
  },
  -- Mason LSP Config
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "prismals" },
        automatic_installation = true,
      })
    end,
  },
  -- Surround
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end
  },
  {
    "sindrets/diffview.nvim",
    opts = function()
      local actions = require("diffview.actions")

      local function diff_windows()
        local wins = vim.api.nvim_tabpage_list_wins(0)
        local diff_wins = vim.tbl_filter(function(win)
          local bufnr = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[bufnr].filetype
          return ft ~= "DiffviewFiles" and ft ~= "DiffviewFileHistory"
        end, wins)

        table.sort(diff_wins, function(a, b)
          local a_pos = vim.api.nvim_win_get_position(a)
          local b_pos = vim.api.nvim_win_get_position(b)
          if a_pos[1] == b_pos[1] then
            return a_pos[2] < b_pos[2]
          end
          return a_pos[1] < b_pos[1]
        end)

        return diff_wins
      end

      local function focus_first_diff_window()
        local wins = diff_windows()
        if wins[1] then
          vim.api.nvim_set_current_win(wins[1])
        end
      end

      local function focus_next_diff_window()
        local wins = diff_windows()
        if #wins == 0 then
          return
        end

        local current_win = vim.api.nvim_get_current_win()
        for i, win in ipairs(wins) do
          if win == current_win then
            vim.api.nvim_set_current_win(wins[(i % #wins) + 1])
            return
          end
        end

        vim.api.nvim_set_current_win(wins[1])
      end

      local function select_entry_and_focus_first_diff_window()
        actions.select_entry()
        vim.defer_fn(focus_first_diff_window, 20)
      end

      local function goto_file_and_close_diffview()
        actions.goto_file_edit()
        vim.defer_fn(function()
          pcall(vim.cmd, "DiffviewClose")
        end, 20)
      end

      local function yank_file_panel_path()
        local view = require("diffview.lib").get_current_view()
        local item = view and view.panel and view.panel:get_item_at_cursor()

        if not (item and item.path) then
          vim.notify("No file path under cursor", vim.log.levels.WARN)
          return
        end

        vim.fn.setreg('"', item.path)
        vim.fn.setreg("+", item.path)
        vim.notify("Yanked " .. item.path)
      end

      local function resize_diffview_tabs()
        local ok, lib = pcall(require, "diffview.lib")
        if not ok then
          return
        end

        local current_tab = vim.api.nvim_get_current_tabpage()

        for _, view in ipairs(lib.views or {}) do
          if view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
            vim.api.nvim_set_current_tabpage(view.tabpage)
            vim.cmd("wincmd =")

            if view.panel and view.panel.is_open and view.panel:is_open() then
              view.panel:resize()
            end
          end
        end

        if vim.api.nvim_tabpage_is_valid(current_tab) then
          vim.api.nvim_set_current_tabpage(current_tab)
        end
      end

      vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("diffview_auto_resize", { clear = true }),
        desc = "Resize Diffview layouts when Neovim size changes",
        callback = function()
          vim.schedule(resize_diffview_tabs)
        end,
      })

      local function jump_prev_hunk()
        if vim.bo.filetype == "DiffviewFiles" then
          actions.focus_entry()
          vim.defer_fn(jump_prev_hunk, 20)
          return
        end

        pcall(vim.cmd, "normal! [c")
      end

      local function jump_next_hunk()
        if vim.bo.filetype == "DiffviewFiles" then
          actions.focus_entry()
          vim.defer_fn(jump_next_hunk, 20)
          return
        end

        pcall(vim.cmd, "normal! ]c")
      end

      return {
        enhanced_diff_hl = true, -- Highly recommended for that GitHub look
        view = {
          merge_tool = {
            layout = "diff3_horizontal",
            disable_diagnostics = true,
          },
        },
        file_panel = {
          win_config = {
            position = "bottom",
            height = 16,
          },
        },
        keymaps = {
          view = {
            { "n", "<S-CR>", focus_next_diff_window, { desc = "Cycle old/new diff panes" } },
            { "n", "<S-Down>", jump_next_hunk, { desc = "Jump to next hunk" } },
            { "n", "<S-Up>", jump_prev_hunk, { desc = "Jump to previous hunk" } },
            { "n", "gf", goto_file_and_close_diffview, { desc = "Open file and close diffview" } },
          },
          file_panel = {
            { "n", "<S-CR>", select_entry_and_focus_first_diff_window, { desc = "Open selected diff and focus old pane" } },
            { "n", "<S-Down>", jump_next_hunk, { desc = "Open selected diff and jump to next hunk" } },
            { "n", "<S-Up>", jump_prev_hunk, { desc = "Open selected diff and jump to previous hunk" } },
            { "n", "gf", goto_file_and_close_diffview, { desc = "Open file and close diffview" } },
            { "n", "y", yank_file_panel_path, { desc = "Yank path relative to repo root" } },
          },
        },
        hooks = {
          diff_buf_read = function(bufnr)
            vim.opt_local.foldlevel = 99
            vim.keymap.set('n', ']]', ']c', { buffer = bufnr, desc = "Next Hunk" })
            vim.keymap.set('n', '[[', '[c', { buffer = bufnr, desc = "Prev Hunk" })
          end,
        },
      }
    end,
  },
  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  -- Supermaven
  {
    "supermaven-inc/supermaven-nvim",
    opts = {
      keymaps = {
        accept_suggestion = "<D-d>",
      }
    }
  },
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" }, -- The Notion of Lazy Events
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        python = { "ruff" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
          end
        end,
      })
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' }, -- if you use standalone mini plugins
    opts = {},
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight-night'
    end
  },
  {
    'dmmulroy/ts-error-translator.nvim',
    config = function()
      require("ts-error-translator").setup({
        auto_attach = true,
        servers = {
          "vtsls",
        },
      })
    end
  },
  {
    "Goose97/timber.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("timber").setup({
        log_templates = {
          default = {
            typescriptreact = [[console.log("===%log_target", %log_target)]],
            tsx = [[console.log("===%log_target", %log_target)]],
            javascript = [[console.log("===%log_target", %log_target)]],
            typescript = [[console.log("===%log_target", %log_target)]],
          },
          plain = {
            typescriptreact = [[console.log("===%insert_cursor")]],
            tsx = [[console.log("===%insert_cursor")]],
            javascript = [[console.log("===$insert_cursor")]],
            typescript = [[console.log("===$insert_cursor")]],
          }
        },
        batch_log_templates = {
          default = {
            typescriptreact = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
            tsx = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
            javascript = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
            typescript = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
          }
        }
      })
    end
  },
  { "chrisgrieser/nvim-spider", lazy = true },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup()
      vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
    end,
  },
  {
    "f-person/git-blame.nvim",
    -- load the plugin at startup
    event = "VeryLazy",
    -- Because of the keys part, you will be lazy loading this plugin.
    -- The plugin will only load once one of the keys is used.
    -- If you want to load the plugin at startup, add something like event = "VeryLazy",
    -- or lazy = false. One of both options will work.
    opts = {
      -- your configuration comes here
      -- for example
      enabled = true, -- if you want to enable the plugin
      message_template = " <summary> • <date> • <author> • <<sha>>", -- template for the blame message, check the Message template section for more options
      date_format = "%m-%d-%Y %H:%M:%S", -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },

  }
})
