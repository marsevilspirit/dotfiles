-- HTML parser for formatted problem descriptions.
local treesitter = require 'nvim-treesitter'
-- Refresh runtime paths after vim.pack creates the site directory on first startup.
treesitter.setup { install_dir = vim.fn.stdpath 'data' .. '/site' }
treesitter.install { 'html' }

require('leetcode').setup {
  lang = 'cpp',
  cn = { enabled = true },
  picker = { provider = 'snacks-picker' },
  plugins = { non_standalone = true },
  editor = { reset_previous_code = false },
  injector = {
    cpp = {
      -- Standard headers work with macOS clangd; bits/stdc++.h is GCC-specific.
      imports = function()
        return {
          '#include <algorithm>',
          '#include <string>',
          '#include <unordered_map>',
          '#include <vector>',
          'using namespace std;',
        }
      end,
    },
  },
}

local map = vim.keymap.set
map('n', '<leader>ll', '<cmd>Leet<CR>', { desc = '[L]eetCode menu' })
map('n', '<leader>lf', '<cmd>Leet list<CR>', { desc = '[L]eetCode [F]ind problem' })
map('n', '<leader>lr', '<cmd>Leet run<CR>', { desc = '[L]eetCode [R]un tests' })
map('n', '<leader>ls', '<cmd>Leet submit<CR>', { desc = '[L]eetCode [S]ubmit' })
map('n', '<leader>ld', '<cmd>Leet desc<CR>', { desc = '[L]eetCode [D]escription' })
map('n', '<leader>lc', '<cmd>Leet lang<CR>', { desc = '[L]eetCode [C]hange language' })
