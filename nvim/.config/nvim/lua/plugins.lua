-- Plugin setup with lazy.nvim

-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

-- Set up plugins
require("lazy").setup({
  {
    "tpope/vim-fugitive",
    config = function()
      --vim-fugitive
      vim.keymap.set('n', '<leader>gs', ':Git<CR>', { noremap = true, desc = 'git status' }) --git status
      vim.keymap.set('n', '<leader>ga', ':Git add ', { noremap = true, desc = 'git add ' })
      vim.keymap.set('n', '<leader>gA', ':Git add .<CR>', { noremap = true, desc = 'git add .' })
      vim.keymap.set('n', '<leader>gp', ':Git push --quiet <CR>', { noremap = true, desc = 'git push' })
      vim.keymap.set('n', '<leader>gc', ':Git commit -qam "', { noremap = true, desc = 'git commit -am' })
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup()
      --gitsigns
      vim.keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk<CR>",
        { noremap = true, desc = "Gitsigns: preview [h]unk" })
      vim.keymap.set("n", "<leader>gi", ":Gitsigns preview_hunk_inline<CR>",
        { noremap = true, desc = "Gitsigns: preview hunk [i]nline" })
    end
  },
  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      "nvim-tree/nvim-web-devicons", -- optional
    },
    config = function()
      require('config.telescope')
    end
  },
  {
    "nvim-pack/nvim-spectre",
    event = "VeryLazy",
    config = function()
      require("spectre").setup({
        -- Optional: you can add your own configuration options here.
        -- For example, to set the open command to a new split:
        -- open_cmd = "vsplit",
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  -- Telescope file browser
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  },
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      { "prisma/vim-prisma", ft = "prisma" },
    },
    config = function()
      require('config.treesitter')
    end
  },
  -- -- Auto tags
  -- {
  --   "windwp/nvim-ts-autotag",
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  --   config = function()
  --     require("config.nvim-ts-autotag")
  --   end
  -- },
  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/nvim-cmp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim"
    },
    config = function()
      require('config.lsp')
    end
  },
  -- Mason
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate", -- :MasonUpdate updates registry contents
    config = function()
      require("mason").setup()
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
  -- Treesitter context comment string
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup({
        enable_autocmd = false, -- Disable its autocommands because using Comment.nvim integration
      })
    end
  },
  -- Null-ls
  {
    "nvimtools/none-ls.nvim",
    config = function()
      require('config.null-ls')
    end,
    requires = { "nvim-lua/plenary.nvim" },
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
  -- Comments
  {
    'numToStr/Comment.nvim',
    config = function()
      require('config.comment')
    end
  },
  -- Git blame
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = true,
      message_template = " <summary> • <date> • <author> • <<sha>>",
      date_format = "%m-%d-%Y %H:%M:%S",
      virtual_text_column = 1,
    }
  },

  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  -- Flash
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Nvim-tree
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      hijack_netrw = false
    }
  },
  -- Bufferline
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('config.bufferline')
    end,
  },
  -- Snipe
  -- {
  --   "leath-dub/snipe.nvim",
  --   keys = {
  --     { "pb", function() require("snipe").open_buffer_menu() end, desc = "Open Snipe buffer menu" }
  --   },
  --   opts = {}
  -- },
  -- Supermaven
  {
    "supermaven-inc/supermaven-nvim",
    opts = {
      keymaps = {
        accept_suggestion = "<D-d>",
      }
    }
  },
  -- Yazi
  ---@type LazySpec
  {
    "mikavilpas/yazi.nvim",
    dependencies = {
      -- check the installation instructions at
      -- https://github.com/folke/snacks.nvim
      "folke/snacks.nvim"
    },
    keys = {
      -- 👇 in this section, choose your own keymappings!
      {
        "<leader>ly",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
      {
        -- Open in the current working directory
        "<leader>lY",
        "<cmd>Yazi cwd<cr>",
        desc = "Open the file manager in nvim's working directory",
      },
    },
    ---@type YaziConfig | {}
    opts = {
      -- if you want to open yazi instead of netrw, see below for more info
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
    },
    -- 👇 if you use `open_for_directories=true`, this is recommended
    init = function()
      -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
      -- vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
  },
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('config.dashboard')
    end,
    dependencies = { { 'nvim-tree/nvim-web-devicons' } }
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
      })
      vim.cmd.colorscheme("catppuccin")
    end
  },
  {
    "mfussenegger/nvim-lint",
    lazy = false,

    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint" },
        javascriptreact = { "eslint" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
        python = { "ruff" },
      }

      -- Helper function to find virtual environment
      local function get_python_path()
        -- Try to find project root
        local root_dir = vim.fs.dirname(vim.fs.find({ "pyproject.toml", "setup.py", ".git" }, {
          upward = true,
          path = vim.fn.expand("%:p:h")
        })[1])

        if root_dir then
          -- Check for common venv locations in project root
          local venv_paths = {
            ".venv/bin/python",
            "venv/bin/python",
            ".virtualenv/bin/python",
          }

          for _, venv_path in ipairs(venv_paths) do
            local full_path = root_dir .. "/" .. venv_path
            if vim.fn.executable(full_path) == 1 then
              return full_path
            end
          end

          -- Try poetry from project directory
          if vim.fn.filereadable(root_dir .. "/pyproject.toml") == 1 then
            local handle = io.popen("cd " .. vim.fn.shellescape(root_dir) .. " && poetry env info -p 2>/dev/null")
            if handle then
              local poetry_venv = handle:read("*a"):gsub("%s+", "")
              handle:close()
              if poetry_venv ~= "" and poetry_venv ~= "nil" then
                local python_path = poetry_venv .. "/bin/python"
                if vim.fn.executable(python_path) == 1 then
                  return python_path
                end
              end
            end
          end
        end

        -- Fallback to system python
        return "python3"
      end

      -- Configure ruff to use venv
      local function get_ruff_cmd()
        local python = get_python_path()
        local venv_dir = vim.fn.fnamemodify(python, ":h:h")
        local ruff_path = venv_dir .. "/bin/ruff"

        if vim.fn.executable(ruff_path) == 1 then
          return ruff_path
        else
          return "ruff"
        end
      end

      -- Override eslint to prefer local installation
      local eslint = lint.linters.eslint
      eslint.cmd = "eslint_d"

      -- Add args to make it use local config
      eslint.args = {
        "--format",
        "json",
        "--stdin",
        "--stdin-filename",
        function() return vim.api.nvim_buf_get_name(0) end,
      }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("LinterAutocmds", { clear = true }),
        callback = function()
          -- Try local node_modules eslint first
          local root_dir = vim.fs.dirname(vim.fs.find({ "package.json",
            ".eslintrc.js", ".eslintrc.json" }, {
            upward = true,
            path = vim.fn.expand("%:p:h")
          })[1])

          if root_dir then
            local local_eslint = root_dir .. "/node_modules/.bin/eslint_d"
            if vim.fn.executable(local_eslint) == 1 then
              lint.linters.eslint.cmd = local_eslint
            end
          end

          -- Set ruff to use venv for Python files
          if vim.bo.filetype == "python" then
            lint.linters.ruff.cmd = get_ruff_cmd()
          end

          lint.try_lint()
        end,
      })
    end,
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()
    end
  },
  {
    "marcocofano/excalidraw.nvim",
    config = function()
      require("excalidraw").setup()
    end
  },
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeHide", "UndotreeFocus" },
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  }
})

require("gitsigns").setup()
