-- agent-comments/render.lua
-- Virtual-text box rendering for agent comments

local data = require("agent-comments.data")

local M = {}

local ns = vim.api.nvim_create_namespace("agent_comments")

-- State (shared with main module)
M.enabled = true
M.show_resolved = false -- false = unresolved only, true = all

-- ── Highlight Groups ───────────────────────────────────────────────────

local function setup_highlights()
  -- Active comment box
  vim.api.nvim_set_hl(0, "AgentCommentBox", { bg = "#1a2332", fg = "#8db4e6" })
  vim.api.nvim_set_hl(0, "AgentCommentBorder", { fg = "#3d5a80" })
  vim.api.nvim_set_hl(0, "AgentCommentIcon", { fg = "#58a6ff" })
  vim.api.nvim_set_hl(0, "AgentCommentText", { bg = "#1a2332", fg = "#c0cfe0" })
  -- Resolved comment box
  vim.api.nvim_set_hl(0, "AgentCommentResolved", { bg = "#1a2a1a", fg = "#6dba6d" })
  vim.api.nvim_set_hl(0, "AgentCommentResolvedText", { bg = "#1a2a1a", fg = "#9abd9a" })
  -- Line highlight for commented lines
  vim.api.nvim_set_hl(0, "AgentCommentLine", { bg = "#141d2b" })
  vim.api.nvim_set_hl(0, "AgentCommentLineResolved", { bg = "#142014" })
end

local function word_wrap(text, max_width)
  local lines = {}
  for _, paragraph in ipairs(vim.split(text, "\n")) do
    if #paragraph == 0 then
      table.insert(lines, "")
    else
      while #paragraph > max_width do
        -- Find a space to break at within max_width
        local segment = paragraph:sub(1, max_width)
        local space_idx = segment:match("^.+"):find(" +$")
        -- Actually just find last space in the segment
        local last_space = nil
        for i = #segment, 1, -1 do
          if segment:sub(i, i) == " " then
            last_space = i
            break
          end
        end
        if last_space then
          table.insert(lines, segment:sub(1, last_space - 1))
          paragraph = paragraph:sub(last_space + 1):match("^%s*(.*)") or ""
        else
          -- No space found, hard break at max_width
          table.insert(lines, segment)
          paragraph = paragraph:sub(max_width + 1)
        end
      end
      if #paragraph > 0 then
        local trimmed = paragraph:match("^%s*(.*)") or paragraph
        if #trimmed > 0 then
          table.insert(lines, trimmed)
        end
      end
    end
  end
  return lines
end

-- ── Rendering ──────────────────────────────────────────────────────────

local function render_comment(bufnr, comment)
  local line = comment.endLine - 1 -- 0-indexed, show below endLine
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line >= line_count then
    line = line_count - 1
  end
  if line < 0 then
    line = 0
  end

  local is_resolved = comment.status == "resolved"
  local icon = is_resolved and " ✓" or " ●"
  local border_hl = "AgentCommentBorder"
  local icon_hl = is_resolved and "AgentCommentResolved" or "AgentCommentIcon"
  local text_hl = is_resolved and "AgentCommentResolvedText" or "AgentCommentText"
  local line_hl = is_resolved and "AgentCommentLineResolved" or "AgentCommentLine"

  -- Highlight the commented lines
  for l = (comment.startLine - 1), math.min(comment.endLine - 1, line_count - 1) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, l, 0, {
      line_hl_group = line_hl,
      priority = 10,
    })
  end

  -- Build box lines
  local raw_msg_lines = vim.split(comment.message, "\n")
  local short_id = comment.id:sub(1, 8)
  local max_width = 60 -- cap box width for wrapping
  for _, ml in ipairs(raw_msg_lines) do
    if #ml > max_width then
      max_width = 60
      break
    end
  end
  local header = icon .. " " .. short_id
  if #header > max_width then
    max_width = #header
  end
  max_width = math.max(max_width, 30)

  -- Wrap long messages
  local msg_lines = {}
  for _, ml in ipairs(raw_msg_lines) do
    local wrapped = word_wrap(ml, max_width)
    for _, wl in ipairs(wrapped) do
      table.insert(msg_lines, wl)
    end
  end

  local pad = "  " -- left padding to indent the box

  -- Top border
  local virt_lines = {}
  table.insert(virt_lines, {
    { pad, "Normal" },
    { "╭" .. string.rep("─", max_width + 2) .. "╮", border_hl },
  })

  -- Header line
  local header_pad = string.rep(" ", max_width - #header + 2)
  table.insert(virt_lines, {
    { pad, "Normal" },
    { "│", border_hl },
    { icon, icon_hl },
    { " " .. short_id .. header_pad, text_hl },
    { "│", border_hl },
  })

  -- Separator
  table.insert(virt_lines, {
    { pad, "Normal" },
    { "├" .. string.rep("─", max_width + 2) .. "┤", border_hl },
  })

  -- Message lines
  for _, ml in ipairs(msg_lines) do
    local msg_pad = string.rep(" ", max_width - #ml + 1)
    table.insert(virt_lines, {
      { pad, "Normal" },
      { "│", border_hl },
      { " " .. ml .. msg_pad, text_hl },
      { "│", border_hl },
    })
  end

  -- Bottom border
  table.insert(virt_lines, {
    { pad, "Normal" },
    { "╰" .. string.rep("─", max_width + 2) .. "╯", border_hl },
  })

  vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,
    priority = 100,
  })
end

function M.render(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  if not M.enabled then
    return
  end

  local comments = data.get_file_comments(bufnr, M.show_resolved)
  for _, c in ipairs(comments) do
    render_comment(bufnr, c)
  end
end

-- Render all visible buffers
function M.render_all()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      M.render(bufnr)
    end
  end
end

M.setup_highlights = setup_highlights

return M
