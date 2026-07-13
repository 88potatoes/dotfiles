-- agent-comments/data.lua
-- Data access: repo root, loading comments, filtering per-file

local service = require("agent-comments.service")

local M = {}

function M.get_repo_root()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if vim.v.shell_error ~= 0 or not root then
    return vim.fn.getcwd()
  end
  return root
end

function M.load_comments(show_all)
  return service.get({ status = show_all and "all" or nil })
end

function M.get_file_comments(bufnr, show_resolved)
  local root = M.get_repo_root()
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

  local all = M.load_comments(show_resolved)
  local result = {}
  for _, c in ipairs(all) do
    if c.file == rel_path then
      if show_resolved or c.status == "active" then
        table.insert(result, c)
      end
    end
  end
  return result
end

return M
