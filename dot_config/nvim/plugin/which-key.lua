-- Which-key: pending keybind popup
require('which-key').setup {
  delay = 0,
  spec = {
    { '<leader>l', group = '[L]eetCode' },
    { '<leader>s', group = '[S]earch' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
  },
}
