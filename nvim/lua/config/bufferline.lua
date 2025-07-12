-- Basic bufferline configuration
require("bufferline").setup({
  options = {
    -- Basic display settings
    mode = "buffers",     -- "buffers" or "tabs"
    numbers = "none",     -- "none", "ordinal", or "buffer_id"
    
    -- Position and style
    position = "top",     -- "top" or "bottom"
    separator_style = "thin", -- "slant", "thick", "thin" or { 'any', 'any' }
    
    -- Behavior
    diagnostics = "nvim_lsp",
    show_buffer_close_icons = true,
    show_close_icon = true,
    
    -- Style
    color_icons = true,
    always_show_bufferline = true,
  }
})
