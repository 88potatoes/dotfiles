local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.lsp.start({
  name = "lua-language-server",
  cmd = { "lua-language-server" },
    root_dir = vim.fs.dirname(vim.fs.find({'.git', '.vim', 'nvim'}, { upward = true })[1]),
  settings = { Lua = { diagnostics = { globals = {'vim'} } } },
})


vim.g.mapleader = " "

require('plugins')  -- Plugin setup with lazy.nvim
require('options')  -- Vim options and settings
require('keymaps')  -- All keybindings
require('autocmds') -- Autocommands

-- Set GIT_EDITOR to use nvr if Neovim and nvr are available
if vim.fn.has('nvim') == 1 and vim.fn.executable('nvr') == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end

vim.g.lazygit_use_custom_config_file_path = 1
vim.g.lazygit_config_file_path = os.getenv("HOME") .. '/.config/lazygit/config.yml'
vim.g.lazygit_use_neovim_remote = 1

if vim.fn.executable('nvr') == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })


vim.opt.scrolloff = 10    -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
vim.opt.cursorline = true -- Highlight current line


-- Statuslines
local function git_branch()
  local branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
  if branch ~= "" then
    return "  " .. branch .. " "
  end
  return ""
end

-- File type with icon
local function file_type()
  local ft = vim.bo.filetype
  local icons = {
    lua = "[LUA]",
    python = "[PY]",
    javascript = "[JS]",
    html = "[HTML]",
    css = "[CSS]",
    json = "[JSON]",
    markdown = "[MD]",
    vim = "[VIM]",
    sh = "[SH]",
  }

  if ft == "" then
    return "  "
  end

  return (icons[ft] or ft)
end

_G.file_type = file_type
_G.git_branch = git_branch

vim.cmd([[
  highlight StatusLineBold gui=bold cterm=bold
]])


local function set_project_root()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    current_file = vim.fn.getcwd()
  end

  -- Look for project root markers (ordered by priority)
  local root_markers = {
    ".git",
    "package.json",
    "tsconfig.json",
    ".eslintrc.js",
    ".eslintrc.json",
    "Cargo.toml",
    "go.mod",
    "pyproject.toml",
    "init.lua",
    "lazy-lock.json",
  }

  -- Find the root directory
  local root_dir = vim.fs.dirname(vim.fs.find(root_markers, {
    upward = true,
    path = vim.fs.dirname(current_file),
  })[1])

  -- If found, change to that directory
  if root_dir then
    vim.cmd("cd " .. root_dir)
    vim.notify("Project root: " .. root_dir, vim.log.levels.INFO)
  end
end

-- Run when opening a file
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = vim.api.nvim_create_augroup("ProjectRoot", { clear = true }),
  callback = function()
    set_project_root()
  end,
})
