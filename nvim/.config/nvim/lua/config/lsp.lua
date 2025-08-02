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
    { name = 'path' }
  })
})

-- LSP capabilities for completions
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Python setup
lspconfig.pyright.setup {
  capabilities = capabilities
}

local mason_registry = require("mason-registry")
local vue_lsp_path = mason_registry.get_package("vue-language-server"):get_install_path() ..
    '/node_modules/@vue/language-server'

lspconfig.vtsls.setup({
  capabilities = capabilities,
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

lspconfig.gopls.setup({})

lspconfig.jsonls.setup {
  filetypes = { "json", "jsonc" },
  settings = {
    json = {
      validate = { enable = true }
    }
  }
}
