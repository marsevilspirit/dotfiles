-- Loaded with --cmd, before init.lua, so startup failures cannot be hidden by :qa.
local errors = {}
local tools_complete = false
vim.api.nvim_create_autocmd('User', {
  pattern = 'MasonToolsUpdateCompleted',
  once = true,
  callback = function()
    tools_complete = true
  end,
})
local report_error = vim.health.error
vim.health.error = function(message, ...)
  errors[#errors + 1] = message
  return report_error(message, ...)
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = xpcall(function()
        assert(vim.v.errmsg == '', vim.v.errmsg)
        local checks = vim.env.DOTFILES_HEALTH_CHECKS
        if not checks then
          -- Wait for the configured first-start installers, including their failures.
          assert(
            vim.wait(600000, function()
              return tools_complete
            end, 100),
            'Mason installation did not complete'
          )
          local registry = require 'mason-registry'
          for _, name in ipairs {
            'stylua',
            'clangd',
            'rust-analyzer',
            'lua-language-server',
            'gopls',
            'protols',
            'pyright',
            'prettier',
          } do
            assert(registry.is_installed(name), 'Mason package was not installed: ' .. name)
          end
          for _, name in ipairs { 'lua_ls', 'clangd', 'gopls', 'rust_analyzer', 'protols', 'pyright' } do
            local command = vim.lsp.config[name].cmd[1]
            assert(vim.fn.executable(command) == 1, 'Missing LSP executable: ' .. command)
          end
          for _, command in ipairs { 'stylua', 'prettier', 'rg', 'fd' } do
            assert(vim.fn.executable(command) == 1, 'Missing executable: ' .. command)
          end
          assert(
            vim.wait(120000, function()
              return pcall(vim.treesitter.language.add, 'html')
            end, 100),
            'HTML parser installation did not complete'
          )
          assert(vim.treesitter.query.get('html', 'highlights'), 'HTML highlight queries are missing')
          -- Terminal/image support is checked interactively, not in a headless runner.
          checks = 'vim.lsp vim.treesitter nvim-treesitter blink.cmp'
        end
        vim.cmd('checkhealth ' .. checks)
        print(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))
        assert(#errors == 0, table.concat(errors, '\n'))
        assert(vim.v.errmsg == '', vim.v.errmsg)
      end, debug.traceback)
      if not ok then
        local mason_log = vim.fn.stdpath 'log' .. '/mason.log'
        if vim.fn.filereadable(mason_log) == 1 then
          io.stderr:write(table.concat(vim.fn.readfile(mason_log), '\n') .. '\n')
        end
        io.stderr:write(tostring(err) .. '\n')
        vim.cmd 'cquit 1'
      end
      vim.cmd 'qall!'
    end)
  end,
})
