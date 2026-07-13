-- agent-comments.nvim
-- Shows inline agent comments from db.json as virtual text boxes

local data = require("agent-comments.data")
local render = require("agent-comments.render")

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

  -- Create floating buffer at bottom of screen
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

  -- Start in insert mode
  vim.cmd("startinsert")

  -- Submit with <CR> in normal mode, <C-CR> or <C-s> in insert mode
  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local message = vim.trim(table.concat(lines, "\n"))
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })

    if message == "" then
      vim.notify("Comment cancelled (empty)", vim.log.levels.WARN)
      return
    end

    local cmd = string.format("agent-comments add %s %s %s", vim.fn.shellescape(file), lines_arg, vim.fn.shellescape(message))
    local result = vim.fn.system(cmd)
    vim.notify(vim.trim(result), vim.log.levels.INFO)
    render.render()
  end

  local function cancel()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.notify("Comment cancelled", vim.log.levels.INFO)
  end

  local opts = { buffer = buf, silent = true }
  -- Submit
  vim.keymap.set("n", "<CR>", submit, opts)
  vim.keymap.set("i", "<C-s>", submit, opts)
  vim.keymap.set("n", "<C-s>", submit, opts)
  -- Cancel with draft save: removes q and <Esc> (too easy to fat-finger),
  -- uses <C-c> and :cq instead. <Esc> just exits to normal mode.
  local function cancel_with_draft()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = table.concat(lines, "\n")
    local trimmed = vim.trim(text)
    if trimmed ~= "" then
      local draft_dir = vim.fn.expand("~/.local/share/agent-comments/drafts")
      vim.fn.mkdir(draft_dir, "p")
      local draft_file = draft_dir .. "/" .. os.date("%Y%m%d-%H%M%S") .. "-" .. file:gsub("/", "_")
      vim.fn.writefile(vim.split(text, "\n"), draft_file)
      vim.notify("Comment cancelled — draft saved to " .. draft_file, vim.log.levels.WARN)
    end
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  vim.keymap.set({ "n", "i" }, "<C-q>", cancel_with_draft, opts)
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
    local result = vim.fn.system("agent-comments resolve " .. cid)
    vim.notify(vim.trim(result), vim.log.levels.INFO)
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
    local result = vim.fn.system("agent-comments resolve " .. cid)
    vim.notify(vim.trim(result), vim.log.levels.INFO)
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
    local result = vim.fn.system("agent-comments delete " .. cid)
    vim.notify(vim.trim(result), vim.log.levels.INFO)
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
