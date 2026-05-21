-- Minimal Neovim helper for zellij-mru-send.
-- Copy this into your nvim config or require it from here.

local M = {}

local function shell_quote(s)
  return vim.fn.shellescape(s)
end

local function visual_range(opts)
  opts = opts or {}

  -- In an active visual mapping, '< and '> can still point at the previous
  -- selection. Use live visual endpoints instead.
  local mode = opts.mode or vim.fn.mode()
  local active_visual = mode == 'v' or mode == 'V' or mode == '\22'
  local s = active_visual and vim.fn.getpos('v') or vim.fn.getpos("'<")
  local e = active_visual and vim.fn.getpos('.') or vim.fn.getpos("'>")

  local start_line, start_col = s[2], s[3]
  local end_line, end_col = e[2], e[3]

  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  return start_line, start_col, end_line, end_col, mode
end

local function selected_text(opts)
  local start_line, start_col, end_line, end_col, mode = visual_range(opts)
  local lines = vim.fn.getline(start_line, end_line)
  if #lines == 0 then
    return "", start_line, end_line
  end

  local selection_mode = mode
  if selection_mode ~= 'v' and selection_mode ~= 'V' and selection_mode ~= '\22' then
    selection_mode = vim.fn.visualmode()
  end

  if selection_mode ~= 'V' then
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
    lines[1] = string.sub(lines[1], start_col)
  end

  return table.concat(lines, "\n"), start_line, end_line
end

function M.send_visual(opts)
  opts = opts or {}
  local script = opts.script or "zellij-mru-send"
  local enter = opts.enter ~= false

  local text, start_line, end_line = selected_text({ mode = opts.mode })
  if text == "" then
    vim.notify("No visual selection", vim.log.levels.WARN)
    return
  end

  local file = vim.fn.expand("%:p")
  local rel = vim.fn.fnamemodify(file, ":.")
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text"

  local payload = table.concat({
    "Context from nvim:",
    "File: " .. rel,
    "Lines: " .. start_line .. "-" .. end_line,
    "",
    "```" .. ft,
    text,
    "```",
    "",
  }, "\n")

  local cmd = script .. (enter and " --enter" or "")
  local full = "printf %s " .. shell_quote(payload) .. " | " .. cmd
  local out = vim.fn.system(full)
  if vim.v.shell_error ~= 0 then
    vim.notify(out, vim.log.levels.ERROR)
  else
    vim.notify("Sent selection to previous zellij pane", vim.log.levels.INFO)
  end
end

return M
