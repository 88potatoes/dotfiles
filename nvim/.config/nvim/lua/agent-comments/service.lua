-- agent-comments/service.lua
-- Single place that shells out to the `agent-comments` CLI.
-- All other modules go through here so the CLI implementation is abstracted away.

local M = {}

local function run(cmd)
  local result = vim.fn.system("agent-comments " .. cmd)
  return vim.trim(result)
end

--- Get comments, optionally filtered.
--- opts: { status = "active"|"resolved"|"draft"|"all"|nil, file = "<path>"|nil }
--- Returns a comments array (parsed JSON), or {} on failure.
function M.get(opts)
  opts = opts or {}
  local cmd = "get --view json"
  if opts.status then
    cmd = cmd .. " -s " .. opts.status
  end
  if opts.file then
    cmd = cmd .. " -f " .. vim.fn.shellescape(opts.file)
  end
  local result = vim.fn.system("agent-comments " .. cmd)
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

--- Add a comment (or a draft when opts.draft). Returns the CLI's result string.
function M.add(file, lines, message, opts)
  opts = opts or {}
  local cmd = string.format(
    "add %s %s %s",
    vim.fn.shellescape(file),
    lines,
    vim.fn.shellescape(message)
  )
  if opts.draft then
    cmd = cmd .. " --draft"
  end
  return run(cmd)
end

--- Resolve a comment by (short) id. Returns the CLI's result string.
function M.resolve(id)
  return run("resolve " .. id)
end

--- Delete a comment by (short) id. Returns the CLI's result string.
function M.delete(id)
  return run("delete " .. id)
end

return M
