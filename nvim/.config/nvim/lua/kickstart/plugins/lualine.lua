return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup {
      sections = {
        lualine_x = {
          require('music-controls')._statusline,
        },
      },
    }
  end,
}

-- return {
--   'akinsho/bufferline.nvim',
--   version = '*',
--   dependencies = 'nvim-tree/nvim-web-devicons',
--   config = function()
--     require('bufferline').setup {
--       options = {
--         diagnostics = 'nvim_lsp',
--         diagnostics_indicator = function(count, level)
--           local icon = level:match 'error' and ' ' or ' '
--           return ' ' .. icon .. count
--         end,
--       },
--     }
--   end,
-- }
