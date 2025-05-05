return {
  'rcarriga/nvim-notify',
  config = function()
    require('notify').setup {
      stages = 'fade',
      merge_duplicates = true,
    }
    -- start notify
    vim.notify = require 'notify'
  end,
}
