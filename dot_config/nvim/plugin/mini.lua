-- Mini.nvim modules

-- Better Around/Inside textobjects
require('mini.ai').setup { n_lines = 500 }

-- Add/delete/replace surroundings
require('mini.surround').setup()

-- Session management
require('mini.sessions').setup()

-- Statusline
local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
  return '%2l:%-2v'
end
