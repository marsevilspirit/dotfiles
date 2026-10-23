-- Load the real native LSP configs without plugins, installers, or server starts.
for _, name in ipairs { 'mason', 'mason-tool-installer', 'fidget', 'lazydev' } do
  package.preload[name] = function()
    return { setup = function() end }
  end
end
package.preload['blink.cmp'] = function()
  return {
    get_lsp_capabilities = function()
      return {}
    end,
  }
end
local enabled = {}
vim.lsp.enable = function(names, value)
  for _, name in ipairs(type(names) == 'table' and names or { names }) do
    enabled[name] = value ~= false
  end
end
vim.lsp.is_enabled = function(name)
  return enabled[name] == true
end
dofile(vim.env.DOTFILES_SOURCE .. '/dot_config/nvim/plugin/lsp.lua')

local base = vim.fs.joinpath(vim.env.DOTFILES_TEST_DIR, 'lsp roots')
local errors = {}
local function write(path, lines)
  local file = vim.fs.joinpath(base, path)
  vim.fn.mkdir(vim.fs.dirname(file), 'p')
  vim.fn.writefile(lines or {}, file)
end

local function check(server, file, expected)
  local bufnr = vim.fn.bufadd(vim.fs.joinpath(base, file))
  vim.fn.bufload(bufnr)
  vim.bo[bufnr].filetype = vim.lsp.config[server].filetypes[1]
  local config = vim.lsp.config[server]
  local root, process_result, process_info
  if type(config.root_dir) == 'function' then
    local done = false
    local system = vim.system
    vim.system = function(command, options, callback)
      local started, executable = vim.uv.hrtime(), vim.fn.exepath(command[1])
      return system(command, options, function(result)
        process_result = result
        process_info = { command = command, executable = executable, cwd = options.cwd, elapsed_ms = (vim.uv.hrtime() - started) / 1e6 }
        callback(result)
      end)
    end
    config.root_dir(bufnr, function(dir)
      root, done = dir, true
    end)
    vim.system = system
    assert(
      vim.wait(10000, function()
        return done
      end),
      'Root callback timed out: ' .. file
    )
  else
    root = vim.fs.root(bufnr, config.root_markers)
  end
  if process_result then
    print(vim.inspect { file = file, info = process_info, result = process_result })
  end
  expected = expected and vim.fs.joinpath(base, expected)
  if root ~= expected then
    errors[#errors + 1] = ('%s %s: expected %s, got %s; process: %s'):format(
      server, file, tostring(expected), tostring(root), vim.inspect(process_result)
    )
  end
end

-- A Git worktree marker must not swallow separate packages or workspaces.
write('repo/.git', { 'gitdir: /unused' })
write('repo/go/go.work', { 'go 1.23', 'use (', './a', './b', ')' })
for _, name in ipairs { 'a', 'b' } do
  write('repo/go/' .. name .. '/go.mod', { 'module example.com/' .. name, 'go 1.23' })
  write('repo/go/' .. name .. '/main.go', { 'package main' })
  check('gopls', 'repo/go/' .. name .. '/main.go', 'repo/go')
end
write('repo/module/go.mod', { 'module example.com/standalone', 'go 1.23' })
write('repo/module/main.go', { 'package main' })
check('gopls', 'repo/module/main.go', 'repo/module')
write('repo/go/nested/go.work', { 'go 1.23', 'use ./module' })
write('repo/go/nested/module/go.mod', { 'module example.com/nested', 'go 1.23' })
write('repo/go/nested/module/main.go', { 'package main' })
check('gopls', 'repo/go/nested/module/main.go', 'repo/go/nested')

write('repo/rust/Cargo.toml', {
  '[workspace]',
  'members = ["crates/a", "crates/b"]',
  'exclude = ["nested", "standalone"]',
  'resolver = "2"',
})
for _, name in ipairs { 'a', 'b' } do
  write('repo/rust/crates/' .. name .. '/Cargo.toml', { '[package]', 'name = "' .. name .. '"', 'version = "0.1.0"' })
  write('repo/rust/crates/' .. name .. '/src/lib.rs')
end
write('repo/rust/nested/Cargo.toml', { '[workspace]', 'members = ["inner"]', 'resolver = "2"' })
write('repo/rust/nested/inner/Cargo.toml', { '[package]', 'name = "inner"', 'version = "0.1.0"' })
write 'repo/rust/nested/inner/src/lib.rs'
write('repo/rust/standalone/Cargo.toml', { '[package]', 'name = "standalone"', 'version = "0.1.0"' })
write 'repo/rust/standalone/src/lib.rs'
write('repo/package/Cargo.toml', { '[package]', 'name = "single"', 'version = "0.1.0"' })
write 'repo/package/src/lib.rs'
write('repo/broken/Cargo.toml', { '[package' })
write 'repo/broken/src/lib.rs'

if vim.fn.executable 'cargo' == 1 then
  check('rust_analyzer', 'repo/rust/crates/a/src/lib.rs', 'repo/rust')
  check('rust_analyzer', 'repo/rust/crates/b/src/lib.rs', 'repo/rust')
  check('rust_analyzer', 'repo/rust/nested/inner/src/lib.rs', 'repo/rust/nested')
  check('rust_analyzer', 'repo/rust/standalone/src/lib.rs', 'repo/rust/standalone')
  check('rust_analyzer', 'repo/package/src/lib.rs', 'repo/package')
  check('rust_analyzer', 'repo/broken/src/lib.rs', 'repo/broken')
  assert(#vim.fn.glob(base .. '/**/Cargo.lock', false, true) == 0, 'Root lookup must not generate lockfiles')
else
  print 'SKIP: Rust workspace lookup requires Cargo; fallback checks still run'
end

local path = vim.env.PATH
vim.env.PATH = ''
check('rust_analyzer', 'repo/rust/crates/a/src/lib.rs', 'repo/rust/crates/a')
check('rust_analyzer', 'repo/package/src/lib.rs', 'repo/package')
vim.env.PATH = path

for server, extension in pairs { gopls = 'go', rust_analyzer = 'rs' } do
  write('repo/loose/file.' .. extension)
  write('loose/file.' .. extension)
  check(server, 'repo/loose/file.' .. extension, 'repo')
  check(server, 'loose/file.' .. extension, nil)
end

-- Hold the process callback until after buffer or LSP state changes.
local system, executable = vim.system, vim.fn.executable
vim.fn.executable = function(command)
  return command == 'cargo' and 1 or executable(command)
end
local function check_delayed(label, mutate, expected_calls)
  vim.lsp.enable 'rust_analyzer'
  local file = 'repo/package/src/' .. label .. '.rs'
  write(file)
  local bufnr = vim.fn.bufadd(vim.fs.joinpath(base, file))
  vim.fn.bufload(bufnr)
  vim.bo[bufnr].filetype = 'rust'
  vim.api.nvim_set_current_buf(bufnr)
  local complete
  vim.system = function(_, _, callback)
    complete = callback
  end
  local calls, root = 0, nil
  vim.lsp.config.rust_analyzer.root_dir(bufnr, function(dir)
    calls, root = calls + 1, dir
  end)
  assert(complete, 'Cargo callback was not captured: ' .. label)
  mutate(bufnr)
  complete { code = 0, signal = 0, stdout = vim.fs.joinpath(base, 'repo/package/Cargo.toml') .. '\n', stderr = '' }
  local drained = false
  vim.schedule(function()
    drained = true
  end)
  assert(
    vim.wait(1000, function()
      return drained
    end),
    'Callback queue did not drain: ' .. label
  )
  if calls ~= expected_calls or (calls == 1 and root ~= vim.fs.joinpath(base, 'repo/package')) then
    errors[#errors + 1] = ('Delayed %s: expected %d root callbacks, got %d (%s)'):format(label, expected_calls, calls, tostring(root))
  end
end
check_delayed('unchanged', function() end, 1)
check_delayed('switched', function(bufnr)
  vim.bo[bufnr].bufhidden = 'hide'
  vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
  assert(vim.api.nvim_buf_is_loaded(bufnr), 'Switching must keep the original buffer loaded')
end, 1)
check_delayed('deleted', function(bufnr)
  vim.cmd('bdelete! ' .. bufnr)
  assert(vim.api.nvim_buf_is_valid(bufnr) and not vim.api.nvim_buf_is_loaded(bufnr), 'bdelete must leave an unloaded buffer')
end, 0)
check_delayed('wiped', function(bufnr)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end, 0)
check_delayed('renamed', function(bufnr)
  vim.api.nvim_buf_set_name(bufnr, vim.fs.joinpath(base, 'repo/rust/standalone/src/renamed.rs'))
end, 0)
check_delayed('filetype', function(bufnr)
  vim.bo[bufnr].filetype = 'text'
end, 0)
check_delayed('disabled', function()
  vim.lsp.enable('rust_analyzer', false)
end, 0)
vim.system, vim.fn.executable = system, executable

if vim.fn.executable 'cargo' == 1 then
  print('Cargo version: ' .. vim.inspect(vim.system({ 'cargo', '-Vv' }, { text = true }):wait(10000)))
end
assert(#errors == 0, table.concat(errors, '\n'))
print 'lsp roots: workspace members share roots; project fallbacks and delayed buffer lifecycle checks passed'
