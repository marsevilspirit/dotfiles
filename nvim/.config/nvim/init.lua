-- Enable fast module loading (improves startup ~30%)
vim.loader.enable()

-- Set <space> as the leader key
-- NOTE: Must happen before plugins are loaded
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Global variables
vim.g.have_nerd_font = true
vim.g.snacks_animate = false

-- [[ Setting options ]]
vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.termguicolors = true

-- Sync clipboard between OS and Neovim (deferred for startup speed)
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = false
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.laststatus = 3

-- [[ Basic Keymaps ]]
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Split navigation with CTRL+<hjkl>
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- File explorer (snacks explorer)
vim.keymap.set('n', '<leader>e', function()
  Snacks.explorer()
end, { desc = 'Toggle file explorer' })

-- Buffer navigation
vim.keymap.set('n', '<C-left>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Prev buffer' })
vim.keymap.set('n', '<C-right>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-L>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-H>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Prev buffer' })

-- [[ Basic Autocommands ]]

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Cancel new line comment
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  pattern = '*',
  callback = function()
    vim.opt.formatoptions = vim.opt.formatoptions - { 'c', 'r', 'o' }
  end,
})

-- Auto save on leaving insert mode
vim.api.nvim_create_autocmd({ 'InsertLeave' }, {
  desc = 'Auto save on leaving insert mode',
  callback = function()
    vim.fn.execute 'silent! write'
  end,
})

-- [[ PackChanged hooks — MUST be defined before vim.pack.add() ]]
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then
      return
    end

    if name == 'LuaSnip' then
      if vim.fn.executable 'make' == 1 then
        vim.system({ 'make', 'install_jsregexp' }, { cwd = ev.data.path })
      end
    elseif name == 'markdown-preview.nvim' then
      vim.system({ 'yarn', 'install' }, { cwd = ev.data.path .. '/app' })
    end
  end,
})

-- [[ Install and load plugins with vim.pack ]]
vim.pack.add {
  -- Colorscheme
  'https://github.com/folke/tokyonight.nvim',

  -- UI / Core
  'https://github.com/folke/which-key.nvim',
  'https://github.com/folke/snacks.nvim',
  'https://github.com/folke/todo-comments.nvim',
  'https://github.com/folke/flash.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/akinsho/bufferline.nvim',

  -- Completion
  'https://github.com/saghen/blink.lib',
  'https://github.com/saghen/blink.cmp',
  'https://github.com/L3MON4D3/LuaSnip',
  'https://github.com/folke/lazydev.nvim',

  -- LSP
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
  'https://github.com/j-hui/fidget.nvim',

  -- Formatting / Linting
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/mfussenegger/nvim-lint',

  -- Git
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/sindrets/diffview.nvim',


  -- Language-specific
  'https://github.com/maxandron/goplements.nvim',

  -- Editing
  'https://github.com/echasnovski/mini.nvim',
  'https://github.com/NMAC427/guess-indent.nvim',
  'https://github.com/windwp/nvim-autopairs',

  -- Misc
  'https://github.com/zbirenbaum/copilot.lua',
  'https://github.com/wakatime/vim-wakatime',
}

-- vim: ts=2 sts=2 sw=2 et
