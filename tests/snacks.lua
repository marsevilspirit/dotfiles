-- Exercise the real mapping without installing Snacks or starting a picker.
local calls = 0
local snacks = {
  setup = function() end,
  picker = {
    grep_buffers = function()
      calls = calls + 1
    end,
  },
}
package.loaded.snacks = snacks
_G.Snacks = snacks
vim.g.mapleader = ' '
dofile(vim.env.DOTFILES_SOURCE .. '/dot_config/nvim/plugin/snacks.lua')
local mapping = vim.fn.maparg(' s/', 'n', false, true)
assert(mapping.desc == '[S]earch [/] in Open Files')
local search = mapping.callback

search()
assert(calls == 0, 'Unnamed buffers must not start a search')

local terminal = vim.api.nvim_create_buf(true, false)
vim.api.nvim_open_term(terminal, {})
vim.api.nvim_buf_set_name(terminal, 'term://dotfiles-test//123:shell')
search()
assert(calls == 0, 'Terminal buffers must not start a search')

local file = vim.env.DOTFILES_TEST_DIR .. '/snacks-open.txt'
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(buf, file)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'not saved yet' })
search()
assert(calls == 0, 'Unsaved files must not start a search')

vim.fn.writefile({ 'on disk' }, file)
vim.bo[buf].buflisted = false
search()
assert(calls == 0, 'Unlisted files must not start a search')

vim.bo[buf].buflisted = true
search()
assert(calls == 1, 'A listed file on disk must open the native buffer picker')

vim.fn.delete(file)
search()
assert(calls == 1, 'Deleted files must not start a search')
print 'snacks: empty searches skipped; listed files use the native buffer picker'
