-- Telescope configuration
local telescope = require('telescope')

telescope.load_extension('file_browser')

-- PATH_DISPLAY START
-- https://yeripratama.com/blog/customizing-nvim-telescope/
-- local function normalize_path(path)
--   return path:gsub("\\", "/")
-- end
--
-- local function normalize_cwd()
--   return normalize_path(vim.loop.cwd()) .. "/"
-- end
--
-- local function is_subdirectory(cwd, path)
--   return string.lower(path:sub(1, #cwd)) == string.lower(cwd)
-- end
--
-- local function split_filepath(path)
--   local normalized_path = normalize_path(path)
--   local normalized_cwd = normalize_cwd()
--   local filename = normalized_path:match("[^/]+$")
--
--   if is_subdirectory(normalized_cwd, normalized_path) then
--     local stripped_path = normalized_path:sub(#normalized_cwd + 1, -(#filename + 1))
--     return stripped_path, filename
--   else
--     local stripped_path = normalized_path:sub(1, -(#filename + 1))
--     return stripped_path, filename
--   end
-- end
--
-- local function path_display(_, path)
--   local stripped_path, filename = split_filepath(path)
--   if filename == stripped_path or stripped_path == "" then
--     return filename
--   end
--   return string.format("%s ~ %s", filename, stripped_path)
-- end
-- PATH_DISPLAY END

telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<M-BS>"] = function()
          vim.api.nvim_input("<C-w>") -- Ctrl-w is the default vim command to delete a word backward
        end,
        ["<D-BS>"] = function()
          vim.api.nvim_input("dd")
        end
      }
    },
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        width = { padding = 0 },
        height = { padding = 0 },
        preview_width = 0.5,
      },
    },
    sorting_strategy = "ascending",
    path_display = { "smart" },
  },
  extensions = {
    file_browser = {
      theme = "ivy",
      hijack_netrw = true,
    },
  }
})

return telescope
