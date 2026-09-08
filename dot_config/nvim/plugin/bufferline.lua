-- Bufferline: tab-like buffer display
require('bufferline').setup {
  options = {
    diagnostics = 'nvim_lsp',
    diagnostics_indicator = function(count) return '  ' .. count end,
  },
}
