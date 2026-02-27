-- Vim options and settings

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Disable netrw (since you're using nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Register language handlers
vim.treesitter.language.register('tsx', 'typescriptreact')
vim.treesitter.language.register('prisma', 'prisma')


-- Visual settings
vim.opt.termguicolors = true                      -- Enable 24-bit colors
vim.opt.signcolumn = "yes"                        -- Always show sign column
vim.opt.showmatch = true                          -- Highlight matching brackets
vim.opt.matchtime = 2                             -- How long to show matching bracket
vim.opt.cmdheight = 1                             -- Command line height
vim.opt.completeopt = "menuone,noinsert,noselect" -- Completion options
vim.opt.showmode = false                          -- Don't show mode in command line
vim.opt.pumheight = 10                            -- Popup menu height
vim.opt.pumblend = 10                             -- Popup menu transparency
vim.opt.conceallevel = 0                          -- Don't hide markup
vim.opt.winblend = 0                              -- Floating window transparency
vim.opt.concealcursor = ""                        -- Don't hide cursor line markup
vim.opt.lazyredraw = true                         -- Don't redraw during macros
vim.opt.synmaxcol = 300                           -- Syntax highlighting limit

-- File handling
vim.opt.backup = false                            -- Don't create backup files
vim.opt.writebackup = false                       -- Don't create backup before writing
vim.opt.swapfile = false                          -- Don't create swap files
vim.opt.undofile = true                           -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300                          -- Faster completion
vim.opt.timeoutlen = 500                          -- Key timeout duration
vim.opt.ttimeoutlen = 0                           -- Key code timeout
vim.opt.autoread = true                           -- Auto reload files changed outside vim
vim.opt.autowrite = false                         -- Don't auto save

-- Behavior settings
vim.opt.hidden = true                   -- Allow hidden buffers
vim.opt.errorbells = false              -- No error bells
vim.opt.backspace = "indent,eol,start"  -- Better backspace behavior
vim.opt.autochdir = false               -- Don't auto change directory
vim.opt.iskeyword:append("-")           -- Treat dash as part of word
vim.opt.path:append("**")               -- include subdirectories in search
vim.opt.selection = "inclusive"         -- Selection behavior
vim.opt.mouse = "a"                     -- Enable mouse support
vim.opt.clipboard:append("unnamedplus") -- Use system clipboard
vim.opt.modifiable = true               -- Allow buffer modifications
vim.opt.encoding = "UTF-8"              -- Set encoding


vim.opt.statusline = " "

local function get_short_path()
  -- There's the notion of a 'Buffer Name'
  -- %:~ reduces the path to be relative to your Home (~) or Current Dir
  local full_path = vim.fn.expand("%:~")
  
  -- If we are in an empty buffer, return a singular placeholder
  if full_path == "" then return "[No Name]" end

  -- Split the path into plural segments
  local segments = {}
  for segment in string.gmatch(full_path, "[^/]+") do
    table.insert(segments, segment)
  end

  -- There's the notion of 'Slicing'
  -- We take the last 3 segments if they exist
  local count = #segments
  local start_index = math.max(1, count - 2) -- -2 because it's inclusive (3 total)
  
  local result = {}
  for i = start_index, count do
    table.insert(result, segments[i])
  end

  -- Join them back into a singular string
  local path_display = table.concat(result, "/")
  
  -- If we cut off folders, prepend '...' to show there's a parent relationship
  if start_index > 1 then
    path_display = ".../" .. path_display
  end

  return path_display
end

local cached_branch = ""

-- Create an "Auto-Command" relationship
-- Every time you enter a buffer (BufEnter), update the cache
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
  callback = function()
    local branch = vim.fn.system("git branch --show-current 2> /dev/null")
    cached_branch = branch:gsub("\n", "")
  end,
})

local function get_git_branch()
  if cached_branch ~= "" then
    return "  "  .. cached_branch .. " "
  end
  return ""
end

_G.MyCustomStatusline = function()
  return table.concat({
    " ",            -- Leading space
    get_git_branch(),
    "|",           -- Separator
    get_short_path(), -- Our filename component
    "%=",           -- SPECIAL ITEM: This pushes everything after it to the right
    "Line: %l/%L ", -- %l is current line, %L is total lines
    "Col: %c ",     -- %c is column
  })
end

vim.opt.winbar = "%!v:lua.MyCustomStatusline()"
vim.opt.laststatus = 0

-- vim.api.nvim_set_hl(0, 'DiffAdd', { bg = '#34462F' })
-- vim.api.nvim_set_hl(0, 'DiffDelete', { bg = '#462F2F' })
-- vim.api.nvim_set_hl(0, 'DiffChange', { bg = '#2F4146' })
-- vim.api.nvim_set_hl(0, 'DiffText', { bg = '#463C2F' })
