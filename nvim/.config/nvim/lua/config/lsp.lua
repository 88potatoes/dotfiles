-- LSP Configuration
local lspconfig = require('lspconfig')
local cmp = require('cmp')
local luasnip = require('luasnip')

-- Mason setup
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls" },
  automatic_installation = true,
})

-- Set up nvim-cmp
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
    -- { name = 'nvim_lsp_signature_help' },
  }),
  window = {
    completion = cmp.config.window.bordered(),
  },
})


-- LSP capabilities for completions
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- local function get_venv_python_path()
--   -- 1. Try to detect a standard '.venv' directory in the project root
--   if vim.fn.isdirectory('./.venv') == 1 then
--     return vim.fn.getcwd() .. '/.venv/bin/python'
--   end
--
--   -- 2. Try to run 'poetry env info -p' and append /bin/python
--   local handle = io.popen("poetry env info -p 2>/dev/null")
--   if handle then
--     local path = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
--     handle:close()
--     if path ~= "" and vim.fn.isdirectory(path) == 1 then
--       return path .. '/bin/python'
--     end
--   end
--
--   -- 3. Fallback to system Python
--   return 'python'
-- end

-- local dynamic_python_path = get_venv_python_path()


lspconfig.pyright.setup({
  capabilities = capabilities,
})

lspconfig.vtsls.setup({
  capabilities = capabilities,
  settings = {
    typescript = {
      preferences = {
        importModuleSpecifier = "non-relative",
        preferTypeOnlyAutoImports = true
      },
    },
  }
})

-- Lua LSP setup
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false, -- Disable third party checks
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- Prisma LSP setup
lspconfig.prismals.setup({
  -- Basic setup
  cmd = { "prisma-language-server", "--stdio" },
  filetypes = { "prisma" },
  capabilities = capabilities,
})

lspconfig.jsonls.setup {
  filetypes = { "json", "jsonc" },
  settings = {
    json = {
      validate = { enable = true }
    }
  }
}

lspconfig.rust_analyzer.setup {
  settings = {
    ['rust-analyzer'] = {
      -- Enable the rust-analyzer formatter.
      -- This makes rust-analyzer use rustfmt for formatting.
      checkOnSave = {
        enable = true,
        command = "clippy"
      },
      inlayHints = {
        -- Optional: Enables inlay hints for better code readability.
        bindingModeHints = {
          enable = true
        },
        chainingHints = {
          enable = true
        }
      }
    }
  }

}

lspconfig.gopls.setup({
  -- Ensure you are using the correct command-line options for gopls
  cmd = { 'gopls' },

  -- THIS SECTION IS KEY FOR FORMATTING
  commands = {
    -- This command tells gopls how to run the external formatter
    Format = {
      function()
        -- Replace 'gofumpt' with 'goimports' if you use that instead
        vim.cmd('silent !gofumpt -w ' .. vim.fn.expand('%'))
      end,
      description = 'Format file with gofumpt',
    },
  },

  settings = {
    gopls = {
      -- Ensure gopls is told to use the external formatter
      gofumpt = true,
      completeUnimported = true,
      usePlaceholders = true,
      staticcheck = true,
    },
  },
})

-- lspconfig.xmlformatter.setup {
--   filetypes = { "xml" },
--   capabilities = capabilities,
-- }
