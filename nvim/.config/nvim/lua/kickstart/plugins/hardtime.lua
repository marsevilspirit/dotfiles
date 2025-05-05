return {
  'm4xshen/hardtime.nvim',
  dependencies = { 'MunifTanjim/nui.nvim' },
  config = function()
    require('hardtime').setup {
      max_time = 10000,
      max_count = 50,
    }
  end,
}
