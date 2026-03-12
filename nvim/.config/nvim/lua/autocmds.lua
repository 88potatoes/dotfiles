if vim.g.my_loaded_ts_context_commentstring and vim.g.my_loaded_ts_context_commentstring ~= 0 then
  return
end

vim.g.my_loaded_ts_context_commentstring = 1

print('loading context commentstring')

local group = vim.api.nvim_create_augroup('ts_context_commentstring', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  desc = 'Set up nvim-ts-context-commentstring for each buffer that has Treesitter active',
  callback = function(args)
    local function is_treesitter_active(bufnr)
      bufnr = bufnr or 0

      -- get_parser will throw an error if Treesitter is not set up for the buffer
      local ok, _ = pcall(vim.treesitter.get_parser, bufnr)

      return ok
    end

    local function setup_buffer(bufnr)
      if not is_treesitter_active(bufnr) then
        return
      end

      local group = vim.api.nvim_create_augroup('context_commentstring_ft', { clear = true })
      vim.api.nvim_create_autocmd('CursorHold', {
        buffer = bufnr,
        group = group,
        desc = 'Change the commentstring on cursor hold using Treesitter',
        callback = function()
          local function update_commentstring(args)
            local function calculate_commentstring(args)
              args = args or {}

              local languages_config = {
                -- Languages that have a single comment style
                astro = '<!-- %s -->',
                c = '/* %s */',
                cpp = { __default = '// %s', __multiline = '/* %s */' },
                css = '/* %s */',
                cue = '// %s',
                gleam = '// %s',
                glimmer = '{{! %s }}',
                go = { __default = '// %s', __multiline = '/* %s */' },
                graphql = '# %s',
                haskell = '-- %s',
                handlebars = '{{! %s }}',
                hcl = { __default = '# %s', __multiline = '/* %s */' },
                html = '<!-- %s -->',
                htmldjango = { __default = '{# %s #}', __multiline = '{% comment %} %s {% endcomment %}' },
                ini = '; %s',
                lua = { __default = '-- %s', __multiline = '--[[ %s ]]' },
                nix = { __default = '# %s', __multiline = '/* %s */' },
                php = { __default = '// %s', __multiline = '/* %s */' },
                python = { __default = '# %s', __multiline = '""" %s """' },
                rego = '# %s',
                rescript = { __default = '// %s', __multiline = '/* %s */' },
                scss = { __default = '// %s', __multiline = '/* %s */' },
                sh = '# %s',
                bash = '# %s',
                solidity = { __default = '// %s', __multiline = '/* %s */' },
                sql = '-- %s',
                svelte = '<!-- %s -->',
                terraform = { __default = '# %s', __multiline = '/* %s */' },
                twig = '{# %s #}',
                typescript = { __default = '// %s', __multiline = '/* %s */' },
                typst = { __default = '// %s', __multiline = '/* %s */' },
                vim = '" %s',
                vue = '<!-- %s -->',
                zsh = '# %s',
                kotlin = { __default = '// %s', __multiline = '/* %s */' },
                roc = '# %s',

                -- Languages that can have multiple types of comments
                tsx = {
                  __default = '// %s',
                  __multiline = '/* %s */',
                  jsx_element = '{/* %s */}',
                  jsx_fragment = '{/* %s */}',
                  jsx_attribute = { __default = '// %s', __multiline = '/* %s */' },
                  comment = { __default = '// %s', __multiline = '/* %s */' },
                  call_expression = { __default = '// %s', __multiline = '/* %s */' },
                  statement_block = { __default = '// %s', __multiline = '/* %s */' },
                  spread_element = { __default = '// %s', __multiline = '/* %s */' },
                },
                templ = {
                  __default = '// %s',
                  component_block = '<!-- %s -->',
                },
              }

              local key = args.key or '__default'
              local location = args.location or nil

              local function get_node_at_cursor_start_of_line(only_languages, location)
                local function get_cursor_line_non_whitespace_col_location()
                  local cursor = vim.api.nvim_win_get_cursor(0)
                  local first_non_whitespace_col = vim.fn.match(vim.fn.getline '.', '\\S')

                  return {
                    cursor[1] - 1,
                    first_non_whitespace_col,
                  }
                end

                location = location or get_cursor_line_non_whitespace_col_location()
                local range = {
                  location[1],
                  location[2],
                  location[1],
                  location[2],
                }
                print("range" .. vim.inspect(range):gsub("\n", " "))

                local function debug_internal_state(node, depth)
                  depth = depth or 0
                  local indent = string.rep("  ", depth)

                  -- Get the symbol name and the 4-point range
                  local type = node:type()
                  local s_row, s_col, e_row, e_col = node:range()

                  -- Format the output to show the "State"
                  print(string.format("%s%s [%d:%d] - [%d:%d]",
                    indent, type, s_row, s_col, e_row, e_col))

                  -- Recursive Relationship: Visit every child node
                  for child in node:iter_children() do
                    debug_internal_state(child, depth + 1)
                  end
                end

                -- default to top level language tree
                local parser = vim.treesitter.get_parser()
                local trees = parser:parse()
                local tree = trees[1]
                local root = tree:root()

                print("tree" .. vim.inspect(tree):gsub("\n", " "))
                local node = parser:named_node_for_range(range)
                print("test_node", node)
                return node, parser
              end

              local node, language_tree = get_node_at_cursor_start_of_line(
                vim.tbl_keys(languages_config),
                location
              )

              print(string.format("node=%s, language_tree=%s", node, language_tree))

              if not node or not language_tree then
                return nil
              end

              local language = language_tree:lang()
              local language_config = languages_config[language]

              local function check_node(node, language_config, commentstring_key)
                commentstring_key = commentstring_key or '__default'

                -- There is no commentstring configuration for this language, use the
                -- `ts_original_commentstring`
                if not language_config then
                  return nil
                end

                -- The configuration is just a simple `commentstring` string, no need to do
                -- any extra Node traversal
                if type(language_config) == 'string' then
                  return language_config
                end

                -- There is no node, we have reached the top-most node, use the default
                -- commentstring from language config
                if not node then
                  return language_config[commentstring_key] or language_config.__default or language_config
                end

                local node_type = node:type()
                local match = language_config[node_type]

                if match then
                  return match[commentstring_key] or match.__default or match
                end

                -- Recursively check the parent node
                return check_node(node:parent(), language_config, commentstring_key)
              end

              local a = check_node(node, language_config, key)
              print("a", a)
              return a
            end

            local found_commentstring = calculate_commentstring(args)
            print("found_commentstring", found_commentstring)

            local cs = vim.treesitter.language.get_filetypes(vim.treesitter.get_parser(0):lang())
            for _, ft in ipairs(cs) do
              print(ft .. ": " .. vim.filetype.get_option(ft, 'commentstring'))
            end

            if found_commentstring then
              print("set commentstring", found_commentstring)
              vim.opt_local.commentstring = found_commentstring
              vim.g.commentstring = found_commentstring
            else
              print("no commentstring")
              -- No commentstring was found, default to the default for this buffer
              local original_commentstring = vim.b.ts_original_commentstring
              if original_commentstring then
                vim.api.nvim_buf_set_option(0, 'commentstring', vim.b.ts_original_commentstring)
              end
            end
          end

          update_commentstring()
        end,
      })
    end

    setup_buffer(args.buf)
  end,
})

print('loaded context commentstring')
