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
vim.lsp.enable = function() end
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
  local config = vim.lsp.config[server]
  local root
  if type(config.root_dir) == 'function' then
    local done = false
    config.root_dir(bufnr, function(dir)
      root, done = dir, true
    end)
    assert(
      vim.wait(10000, function()
        return done
      end),
      'Root callback timed out: ' .. file
    )
  else
    root = vim.fs.root(bufnr, config.root_markers)
  end
  expected = expected and vim.fs.joinpath(base, expected)
  if root ~= expected then
    errors[#errors + 1] = ('%s %s: expected %s, got %s'):format(server, file, tostring(expected), tostring(root))
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
assert(#errors == 0, table.concat(errors, '\n'))
print 'lsp roots: workspace members share roots; nested/standalone projects and fallbacks stay separate'
