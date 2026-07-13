-- agent-comments.nvim
-- Shows inline agent comments from db.json as virtual text boxes

local data = require("agent-comments.data")
local render = require("agent-comments.render")
local service = require("agent-comments.service")
local ui = require("agent-comments.ui")

local M = {}

-- ── Actions ────────────────────────────────────────────────────────────

-- Add a comment on the current line (or visual selection)
function M.add()
  local mode = vim.fn.mode()
  local start_line, end_line

  if mode == "v" or mode == "V" or mode == "\22" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    start_line = vim.fn.line("'<")
    end_line = vim.fn.line("'>")
  else
    start_line = vim.fn.line(".")
    end_line = start_line
  end

  local file = vim.fn.expand("%:.")
  local lines_arg = start_line == end_line and tostring(start_line) or (start_line .. ":" .. end_line)
  local lines_label = start_line == end_line and ("L" .. start_line) or ("L" .. start_line .. "-" .. end_line)

  ui.open_comment_editor({
    file = file,
    lines_label = lines_label,
    on_submit = function(message)
      local result = service.add(file, lines_arg, message)
      vim.notify(result, vim.log.levels.INFO)
      render.render()
    end,
    on_cancel_draft = function(message)
      local result = service.add(file, lines_arg, message, { draft = true })
      vim.notify("Comment cancelled — draft saved: " .. result, vim.log.levels.WARN)
    end,
  })
end

-- Pick a comment on the current file to resolve
function M.resolve_pick()
  local bufnr = vim.api.nvim_get_current_buf()
  local comments = data.get_file_comments(bufnr, render.show_resolved)
  local active = vim.tbl_filter(function(c) return c.status == "active" end, comments)

  if #active == 0 then
    vim.notify("No active comments in this file", vim.log.levels.INFO)
    return
  end

  -- If cursor is on/inside a comment, resolve it directly
  local cursor_line = vim.fn.line(".")
  local under_cursor = vim.tbl_filter(function(c)
    return cursor_line >= c.startLine and cursor_line <= c.endLine
  end, active)

  if #under_cursor == 1 then
    local c = under_cursor[1]
    local cid = c.id:sub(1, 8)
    local result = service.resolve(cid)
    vim.notify(result, vim.log.levels.INFO)
    render.render()
    return
  end

  -- Multiple or none under cursor — show picker
  local items = {}
  for _, c in ipairs(active) do
    local lines = c.startLine == c.endLine and ("L" .. c.startLine) or ("L" .. c.startLine .. "-" .. c.endLine)
    table.insert(items, {
      label = c.id:sub(1, 8) .. "  " .. lines .. "  " .. c.message,
      id = c.id,
      lnum = c.startLine,
    })
  end

  vim.ui.select(items, {
    prompt = "Resolve comment:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    local cid = choice.id:sub(1, 8)
    local result = service.resolve(cid)
    vim.notify(result, vim.log.levels.INFO)
    render.render()
  end)
end

-- Delete a comment — pick from current file
function M.delete_pick()
  local bufnr = vim.api.nvim_get_current_buf()
  local comments = data.get_file_comments(bufnr, render.show_resolved)

  if #comments == 0 then
    vim.notify("No comments in this file", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, c in ipairs(comments) do
    local lines = c.startLine == c.endLine and ("L" .. c.startLine) or ("L" .. c.startLine .. "-" .. c.endLine)
    local status = c.status == "resolved" and "✓" or "●"
    table.insert(items, {
      label = status .. " " .. c.id:sub(1, 8) .. "  " .. lines .. "  " .. c.message,
      id = c.id,
    })
  end

  vim.ui.select(items, {
    prompt = "Delete comment:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    local cid = choice.id:sub(1, 8)
    local result = service.delete(cid)
    vim.notify(result, vim.log.levels.INFO)
    render.render()
  end)
end

-- ── Quickfix ───────────────────────────────────────────────────────────

function M.quickfix()
  local comments = data.load_comments(render.show_resolved)
  if #comments == 0 then
    vim.notify("No agent comments", vim.log.levels.INFO)
    return
  end

  local root = data.get_repo_root()
  local items = {}
  for _, c in ipairs(comments) do
    local filepath = root .. "/" .. c.file
    local status = c.status == "resolved" and "✓" or "●"
    local short_id = c.id:sub(1, 8)
    table.insert(items, {
      filename = filepath,
      lnum = c.startLine,
      end_lnum = c.endLine,
      col = 1,
      text = status .. " [" .. short_id .. "] " .. c.message:gsub("\n", " "),
    })
  end

  vim.fn.setqflist({}, " ", { title = "Agent Comments", items = items })
  vim.cmd("copen")
end

-- ── Commands ───────────────────────────────────────────────────────────

function M.toggle()
  render.enabled = not render.enabled
  render.render_all()
  local state = render.enabled and "ON" or "OFF"
  vim.notify("Agent comments: " .. state, vim.log.levels.INFO)
end

function M.toggle_resolved()
  render.show_resolved = not render.show_resolved
  render.render_all()
  local state = render.show_resolved and "all" or "unresolved only"
  vim.notify("Agent comments: showing " .. state, vim.log.levels.INFO)
end

function M.refresh()
  render.render_all()
end

-- ── Setup ──────────────────────────────────────────────────────────────

function M.setup()
  render.setup_highlights()

  -- Auto-render on buffer enter/read
  local group = vim.api.nvim_create_augroup("AgentComments", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    group = group,
    callback = function(ev)
      -- Small delay so buffer content is ready
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          render.render(ev.buf)
        end
      end, 50)
    end,
  })

  -- Re-render on focus gain (comments may have changed externally)
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      render.render_all()
    end,
  })

  -- User commands
  vim.api.nvim_create_user_command("AgentCommentsToggle", M.toggle, {})
  vim.api.nvim_create_user_command("AgentCommentsToggleResolved", M.toggle_resolved, {})
  vim.api.nvim_create_user_command("AgentCommentsRefresh", M.refresh, {})
  vim.api.nvim_create_user_command("AgentCommentsAdd", M.add, { range = true })
  vim.api.nvim_create_user_command("AgentCommentsResolve", M.resolve_pick, {})
  vim.api.nvim_create_user_command("AgentCommentsDelete", M.delete_pick, {})
  vim.api.nvim_create_user_command("AgentCommentsQuickfix", M.quickfix, {})

  -- Keymaps
  vim.keymap.set("n", "<leader>ac", M.toggle, { desc = "Toggle agent comments" })
  vim.keymap.set("n", "<leader>ar", M.toggle_resolved, { desc = "Toggle resolved agent comments" })
  vim.keymap.set("n", "<leader>aR", M.refresh, { desc = "Refresh agent comments" })
  vim.keymap.set({ "n", "v" }, "<leader>aa", M.add, { desc = "Add agent comment" })
  vim.keymap.set("n", "<leader>ad", M.delete_pick, { desc = "Delete agent comment" })
  vim.keymap.set("n", "<leader>ax", M.resolve_pick, { desc = "Resolve agent comment" })
  vim.keymap.set("n", "<leader>aq", M.quickfix, { desc = "Agent comments quickfix" })
end

return M
