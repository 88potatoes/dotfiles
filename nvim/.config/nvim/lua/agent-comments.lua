-- agent-comments.nvim
-- Shows inline agent comments from db.json as virtual text boxes

local M = {}

local ns = vim.api.nvim_create_namespace("agent_comments")

-- State
M.enabled = true
M.show_resolved = false -- false = unresolved only, true = all

-- ── Helpers ────────────────────────────────────────────────────────────

local function get_repo_root()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if vim.v.shell_error ~= 0 or not root then
    return vim.fn.getcwd()
  end
  return root
end

local function load_comments(show_all)
  local cmd = "agent-comments get --view json"
  if show_all then
    cmd = cmd .. " -s all"
  end
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("agent-comments: " .. vim.trim(result), vim.log.levels.WARN)
    return {}
  end
  local ok, data = pcall(vim.json.decode, result)
  if not ok or not data or not data.comments then
    return {}
  end
  return data.comments
end

local function get_file_comments(bufnr)
  local root = get_repo_root()
  local buf_path = vim.api.nvim_buf_get_name(bufnr)
  if buf_path == "" then
    return {}
  end

  -- Make relative to repo root
  local rel_path = vim.fn.fnamemodify(buf_path, ":.")
  -- Also try relative from repo root
  if buf_path:sub(1, #root) == root then
    rel_path = buf_path:sub(#root + 2)
  end

  local all = load_comments(M.show_resolved)
  local result = {}
  for _, c in ipairs(all) do
    if c.file == rel_path then
      if M.show_resolved or c.status == "active" then
        table.insert(result, c)
      end
    end
  end
  return result
end

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

  local comments = get_file_comments(bufnr)
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
    M.render()
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
  vim.keymap.set("i", "<C-c>", cancel_with_draft, opts)
  vim.keymap.set("n", "<C-c>", cancel_with_draft, opts)
  vim.keymap.set({ "n", "i" }, "<C-q>", cancel_with_draft, opts)
end

-- Pick a comment on the current file to resolve
function M.resolve_pick()
  local bufnr = vim.api.nvim_get_current_buf()
  local comments = get_file_comments(bufnr)
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
    M.render()
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
    M.render()
  end)
end

-- Delete a comment — pick from current file
function M.delete_pick()
  local bufnr = vim.api.nvim_get_current_buf()
  local comments = get_file_comments(bufnr)

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
    M.render()
  end)
end

-- ── Quickfix ───────────────────────────────────────────────────────────

function M.quickfix()
  local comments = load_comments(M.show_resolved)
  if #comments == 0 then
    vim.notify("No agent comments", vim.log.levels.INFO)
    return
  end

  local root = get_repo_root()
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
  M.enabled = not M.enabled
  M.render_all()
  local state = M.enabled and "ON" or "OFF"
  vim.notify("Agent comments: " .. state, vim.log.levels.INFO)
end

function M.toggle_resolved()
  M.show_resolved = not M.show_resolved
  M.render_all()
  local state = M.show_resolved and "all" or "unresolved only"
  vim.notify("Agent comments: showing " .. state, vim.log.levels.INFO)
end

function M.refresh()
  M.render_all()
end

-- ── Setup ──────────────────────────────────────────────────────────────

function M.setup()
  setup_highlights()

  -- Auto-render on buffer enter/read
  local group = vim.api.nvim_create_augroup("AgentComments", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    group = group,
    callback = function(ev)
      -- Small delay so buffer content is ready
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          M.render(ev.buf)
        end
      end, 50)
    end,
  })

  -- Re-render on focus gain (comments may have changed externally)
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      M.render_all()
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
