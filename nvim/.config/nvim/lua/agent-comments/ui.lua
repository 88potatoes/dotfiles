-- agent-comments/ui.lua
-- Floating-window comment editor used by the add action.

local M = {}

--- Open a bottom-of-screen float for writing a comment.
--- opts: {
---   file = string,            -- path (for the window title)
---   lines_label = string,     -- e.g. "L12" or "L10-15"
---   on_submit = function(message),       -- called with trimmed text on submit
---   on_cancel_draft = function(message), -- called with trimmed text on <C-q> if non-empty
--- }
function M.open_comment_editor(opts)
  local file = opts.file
  local lines_label = opts.lines_label
  local on_submit = opts.on_submit
  local on_cancel_draft = opts.on_cancel_draft

  local width = vim.o.columns - 4
  local height = 5
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = vim.o.lines - height - 3,
    col = 2,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " 💬 Comment on " .. vim.fn.fnamemodify(file, ":t") .. ":" .. lines_label .. " ",
    title_pos = "left",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "markdown"
  vim.wo[win].wrap = true
  vim.wo[win].winhl = "Normal:AgentCommentText,FloatBorder:AgentCommentBorder,FloatTitle:AgentCommentIcon"

  vim.cmd("startinsert")

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local function get_text()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    return vim.trim(table.concat(lines, "\n"))
  end

  -- Submit with <CR> in normal mode, <C-s> in insert/normal mode
  local function submit()
    local message = get_text()
    close()
    if message == "" then
      vim.notify("Comment cancelled (empty)", vim.log.levels.WARN)
      return
    end
    if on_submit then
      on_submit(message)
    end
  end

  -- Cancel with draft save (<C-q>): hand non-empty text to the caller.
  local function cancel_with_draft()
    local message = get_text()
    close()
    if message ~= "" and on_cancel_draft then
      on_cancel_draft(message)
    end
  end

  local keymap_opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "<CR>", submit, keymap_opts)
  vim.keymap.set("i", "<C-s>", submit, keymap_opts)
  vim.keymap.set("n", "<C-s>", submit, keymap_opts)
  vim.keymap.set({ "n", "i" }, "<C-q>", cancel_with_draft, keymap_opts)
end

return M
