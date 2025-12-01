vim.g.mapleader = " "

require('plugins')      -- Plugin setup with lazy.nvim
require('options')      -- Vim options and settings
require('keymaps')      -- All keybindings
require('autocmds')     -- Autocommands

-- Set GIT_EDITOR to use nvr if Neovim and nvr are available
if vim.fn.has('nvim') == 1 and vim.fn.executable('nvr') == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end

vim.g.lazygit_use_custom_config_file_path = 1
vim.g.lazygit_config_file_path = '/Users/eric/.config/lazygit/config.yml'
vim.g.lazygit_use_neovim_remote = 1

if vim.fn.executable('nvr') == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end
