-- Exercise the real init.lua without downloading or loading third-party plugins.
vim.pack.add = function() end
dofile(vim.env.DOTFILES_SOURCE .. '/dot_config/nvim/init.lua')
local save = vim.api.nvim_get_autocmds({ event = 'InsertLeave' })[1].callback
local function leave()
  -- Calling the registered callback directly lets BufWritePost observe writes.
  save { buf = vim.api.nvim_get_current_buf() }
end
local file = vim.env.DOTFILES_TEST_DIR .. '/autosave.txt'
vim.cmd.edit(file)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'saved' })
local writes = 0
vim.api.nvim_create_autocmd('BufWritePost', {
  callback = function()
    writes = writes + 1
  end,
})
leave()
assert(vim.fn.readfile(file)[1] == 'saved' and not vim.bo.modified)
leave()
assert(writes == 1, 'Unchanged buffers must not be written again')

vim.bo.readonly = true
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unsaved' })
leave()
assert(writes == 1 and vim.bo.modified, 'Readonly buffers must be skipped')
vim.bo.readonly = false
vim.bo.modifiable = false
leave()
assert(writes == 1, 'Non-modifiable buffers must be skipped')
vim.bo.modifiable = true
vim.bo.buftype = 'nofile'
leave()
assert(writes == 1, 'Special buffers must be skipped')

vim.cmd 'enew!'
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unnamed' })
leave()
assert(writes == 1 and vim.bo.modified, 'Unnamed buffers must be skipped')

vim.api.nvim_buf_set_name(0, vim.env.DOTFILES_TEST_DIR .. '/missing-parent/fail.txt')
local saved = pcall(leave)
assert(not saved and vim.bo.modified, 'Write failures must remain visible and keep changes')
print 'autosave: saved once; skipped unchanged/readonly/special/unnamed; write failure surfaced'
