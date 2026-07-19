local M = {}

local DEFAULT_REV = 'main...HEAD'
local DEFAULT_SCOPE = DEFAULT_REV .. ' --imply-local'
local STATE_PATH = vim.fn.stdpath('state') .. '/diffview-brain.json'

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = 'Diffview Brain' })
end

local function system(args, opts)
  opts = vim.tbl_extend('force', { text = true }, opts or {})
  local result = vim.system(args, opts):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or '')
  end
  return result.stdout or '', nil
end

local function git_root()
  local out, err = system({ 'git', 'rev-parse', '--show-toplevel' })
  if not out then
    return nil, err
  end
  return vim.trim(out)
end

local function read_state()
  if vim.fn.filereadable(STATE_PATH) ~= 1 then
    return { repos = {} }
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(STATE_PATH), '\n'))
  if not ok or type(decoded) ~= 'table' then
    return { repos = {} }
  end

  decoded.repos = decoded.repos or {}
  return decoded
end

local function write_state(state)
  vim.fn.mkdir(vim.fn.fnamemodify(STATE_PATH, ':h'), 'p')
  vim.fn.writefile(vim.split(vim.json.encode(state), '\n'), STATE_PATH)
end

local function repo_scope(state, root, scope)
  state.repos[root] = state.repos[root] or {}
  state.repos[root][scope] = state.repos[root][scope] or {}
  return state.repos[root][scope]
end

local function changed_files(root, rev)
  local out, err = system({ 'git', '-C', root, 'diff', '--name-only', '-z', rev })
  if not out then
    return nil, err
  end

  local files = {}
  for file in out:gmatch('([^%z]+)') do
    table.insert(files, file)
  end
  table.sort(files)
  return files, nil
end

local function patch_hash(root, rev, path)
  local out, err = system({ 'git', '-C', root, 'diff', '--binary', rev, '--', path })
  if not out then
    return nil, err
  end
  return vim.fn.sha256(out)
end

local function is_seen(entry, hash)
  return entry and entry.hash == hash
end

local function current_view()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then
    return nil
  end
  return lib.get_current_view()
end

local function current_file_path(root)
  local view = current_view()
  if view then
    local ok, file = pcall(function()
      return view:infer_cur_file(false)
    end)
    if ok and file and file.path then
      return file.path, file
    end

    if view.cur_entry and view.cur_entry.path then
      return view.cur_entry.path, view.cur_entry
    end

    if view.panel and view.panel.cur_file and view.panel.cur_file.path then
      return view.panel.cur_file.path, view.panel.cur_file
    end
  end

  local name = vim.api.nvim_buf_get_name(0)
  if name ~= '' and root and vim.startswith(name, root .. '/') then
    return name:sub(#root + 2), nil
  end

  return nil
end

local function current_view_paths(root, rev)
  local view = current_view()
  if view and view.panel and view.panel.ordered_file_list then
    local ok, files = pcall(function()
      return view.panel:ordered_file_list()
    end)
    if ok and files then
      local paths = {}
      for _, file in ipairs(files) do
        if file.path then
          table.insert(paths, file.path)
        end
      end
      if #paths > 0 then
        return paths
      end
    end
  end

  return changed_files(root, rev)
end

local function remove_from_list(list, file)
  for i = #list, 1, -1 do
    if list[i] == file or list[i].path == file.path then
      table.remove(list, i)
    end
  end
end

local function prune_file_from_current_view(file)
  local view = current_view()
  if not (view and view.files and view.panel and file) then
    return false
  end

  local ordered = view.panel:ordered_file_list()
  local next_file = nil
  for i, candidate in ipairs(ordered) do
    if candidate == file or candidate.path == file.path then
      next_file = ordered[i + 1] or ordered[i - 1]
      break
    end
  end

  remove_from_list(view.files.conflicting, file)
  remove_from_list(view.files.working, file)
  remove_from_list(view.files.staged, file)
  view.files:update_file_trees()

  if view.panel.cur_file == file or (view.panel.cur_file and view.panel.cur_file.path == file.path) then
    view.panel:set_cur_file(next_file)
  end

  view.panel:update_components()
  view.panel:render()
  view.panel:redraw()
  view.panel:reconstrain_cursor()

  if next_file then
    view:set_file(next_file, false, true)
  elseif view.file_safeguard then
    view:file_safeguard()
  end

  return true
end

local function build_open_command(rev, paths)
  local parts = { 'DiffviewOpen', rev, '--imply-local' }
  if paths and #paths > 0 then
    table.insert(parts, '--')
    for _, path in ipairs(paths) do
      table.insert(parts, vim.fn.fnameescape(path))
    end
  end
  return table.concat(parts, ' ')
end

function M.open_pr_diff(opts)
  opts = opts or {}
  local rev = opts.rev or DEFAULT_REV
  local scope = opts.scope or DEFAULT_SCOPE

  local root, root_err = git_root()
  if not root then
    notify('Not in a git repo: ' .. (root_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  if opts.include_seen then
    vim.cmd(build_open_command(rev))
    return
  end

  local files, files_err = changed_files(root, rev)
  if not files then
    notify('Could not list changed files: ' .. (files_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local state = read_state()
  local seen = repo_scope(state, root, scope)
  local unseen = {}

  for _, path in ipairs(files) do
    local hash, hash_err = patch_hash(root, rev, path)
    if not hash then
      notify('Could not hash ' .. path .. ': ' .. (hash_err or 'unknown error'), vim.log.levels.WARN)
    elseif not is_seen(seen[path], hash) then
      table.insert(unseen, path)
    end
  end

  if #unseen == 0 then
    notify('No unseen diffs. Use <leader>dM to show all.')
    return
  end

  vim.cmd(build_open_command(rev, unseen))
  notify(('Showing %d unseen diff%s (%d hidden)'):format(#unseen, #unseen == 1 and '' or 's', #files - #unseen))
end

function M.mark_current_seen(opts)
  opts = opts or {}
  local rev = opts.rev or DEFAULT_REV
  local scope = opts.scope or DEFAULT_SCOPE

  local root, root_err = git_root()
  if not root then
    notify('Not in a git repo: ' .. (root_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local path, file = current_file_path(root)
  if not path then
    notify('Could not infer current diffview file', vim.log.levels.ERROR)
    return
  end

  local hash, hash_err = patch_hash(root, rev, path)
  if not hash then
    notify('Could not hash ' .. path .. ': ' .. (hash_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local state = read_state()
  repo_scope(state, root, scope)[path] = {
    hash = hash,
    seenAt = os.date('!%Y-%m-%dT%H:%M:%SZ'),
  }
  write_state(state)

  notify('Marked seen: ' .. path)
  if opts.prune then
    prune_file_from_current_view(file or { path = path })
  end
end

function M.mark_visible_seen(opts)
  opts = opts or {}
  local rev = opts.rev or DEFAULT_REV
  local scope = opts.scope or DEFAULT_SCOPE

  local root, root_err = git_root()
  if not root then
    notify('Not in a git repo: ' .. (root_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local paths, paths_err = current_view_paths(root, rev)
  if not paths then
    notify('Could not list visible files: ' .. (paths_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local state = read_state()
  local seen = repo_scope(state, root, scope)
  local count = 0

  for _, path in ipairs(paths) do
    local hash = patch_hash(root, rev, path)
    if hash then
      seen[path] = {
        hash = hash,
        seenAt = os.date('!%Y-%m-%dT%H:%M:%SZ'),
      }
      count = count + 1
    end
  end

  write_state(state)
  notify(('Marked %d file%s seen'):format(count, count == 1 and '' or 's'))
  if opts.refresh then
    M.open_pr_diff({ rev = rev, scope = scope })
  end
end

function M.unmark_current_seen(opts)
  opts = opts or {}
  local scope = opts.scope or DEFAULT_SCOPE

  local root, root_err = git_root()
  if not root then
    notify('Not in a git repo: ' .. (root_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local path = current_file_path(root)
  if not path then
    notify('Could not infer current diffview file', vim.log.levels.ERROR)
    return
  end

  local state = read_state()
  local seen = repo_scope(state, root, scope)
  seen[path] = nil
  write_state(state)
  notify('Unmarked seen: ' .. path)
end

function M.clear_repo(opts)
  opts = opts or {}
  local scope = opts.scope or DEFAULT_SCOPE
  local root, root_err = git_root()
  if not root then
    notify('Not in a git repo: ' .. (root_err or 'unknown error'), vim.log.levels.ERROR)
    return
  end

  local state = read_state()
  if state.repos[root] then
    state.repos[root][scope] = {}
  end
  write_state(state)
  notify('Cleared seen diffs for current repo')
end

return M
