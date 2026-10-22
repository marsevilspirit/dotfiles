-- Native LSP configuration for Neovim 0.12
-- Fully native: vim.lsp.config() + vim.lsp.enable(), no nvim-lspconfig

-- Mason: install LSP servers and tools
require('mason').setup()

require('mason-tool-installer').setup {
  ensure_installed = {
    'stylua',
    'clangd',
    'rust-analyzer',
    'lua-language-server',
    'gopls',
    'protols',
    'pyright',
    'prettier',
  },
}

-- Fidget: LSP progress indicator
require('fidget').setup()

-- Lazydev: Lua LSP for Neovim config
require('lazydev').setup {
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  },
}

-- Global LSP capabilities (blink.cmp provides extended capabilities)
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(),
})

-- Per-server configuration (fully native, no nvim-lspconfig)
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      completion = {
        callSnippet = 'Replace',
      },
    },
  },
})

vim.lsp.config('clangd', {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = { 'compile_commands.json', '.clangd', '.git' },
})

vim.lsp.config('gopls', {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.work', 'go.mod', '.git' },
})

vim.lsp.config('rust_analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, 'Cargo.toml')
    if not root or vim.fn.executable 'cargo' ~= 1 then
      on_dir(root or vim.fs.root(bufnr, '.git'))
      return
    end
    -- Cargo knows workspace membership, including exclusions and nested workspaces.
    vim.system(
      {
        'cargo',
        'locate-project',
        '--workspace',
        '--message-format',
        'plain',
        '--offline',
        '--manifest-path',
        vim.fs.joinpath(root, 'Cargo.toml'),
      },
      { cwd = root, text = true, timeout = 5000 },
      vim.schedule_wrap(function(result)
        local manifest = result.code == 0 and vim.trim(result.stdout or '') or ''
        on_dir(manifest ~= '' and vim.fs.dirname(manifest) or root)
      end)
    )
  end,
})

vim.lsp.config('sourcekit', {
  cmd = { 'sourcekit-lsp' },
  filetypes = { 'swift' },
  root_markers = { 'buildServer.json', '.bsp', 'Package.swift', 'compile_commands.json', '.git' },
})

vim.lsp.config('protols', {
  cmd = { 'protols' },
  filetypes = { 'proto' },
  root_markers = { '.git' },
})

vim.lsp.config('pyright', {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
})

-- Enable LSP servers
vim.lsp.enable {
  'lua_ls',
  'clangd',
  'gopls',
  'rust_analyzer',
  'protols',
  'pyright',
}

-- SourceKit-LSP is provided by Xcode or the Swift toolchain, not Mason.
vim.lsp.enable('sourcekit', vim.fn.executable 'sourcekit-lsp' == 1)

-- Diagnostic configuration
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = {
    source = 'if_many',
    spacing = 2,
  },
}

-- LSP attach autocommand for buffer-local keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Rename
    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Code action
    map('gca', vim.lsp.buf.code_action, '[G]oto [C]ode [A]ction', { 'n', 'x' })

    -- Navigation via Snacks picker
    map('gr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')
    map('gI', function() Snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')
    map('gd', function() Snacks.picker.lsp_definitions() end, '[G]oto [D]efinition')
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    map('gO', function() Snacks.picker.lsp_symbols() end, 'Open Document Symbols')
    map('gW', function() Snacks.picker.lsp_workspace_symbols() end, 'Open Workspace Symbols')
    map('gt', function() Snacks.picker.lsp_type_definitions() end, '[G]oto [T]ype Definition')

    -- Toggle inlay hints
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})
