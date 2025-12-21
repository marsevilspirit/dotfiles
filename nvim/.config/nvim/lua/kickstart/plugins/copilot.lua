return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {
      -- 建议模块配置
      suggestion = {
        enabled = true,
        auto_trigger = true, -- 自动显示建议
        debounce = 75,
        keymap = {
          -- 推荐配置：使用 Ctrl + l (小写L) 来接受建议
          -- 这样可以避免和 nvim-cmp 或其他插件的 Tab 键冲突
          accept = '<C-l>',
          accept_word = false,
          accept_line = false,
          next = '<M-]>', -- Alt + ] 切换下一个建议
          prev = '<M-[>', -- Alt + [ 切换上一个建议
          dismiss = '<C-]>',
        },
      },
      -- 面板模块配置（开启后可通过 :Copilot panel 呼出）
      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = '[[',
          jump_next = ']]',
          accept = '<CR>',
          refresh = 'gr',
          open = '<M-CR>',
        },
        layout = {
          position = 'bottom', -- | top | left | right
          ratio = 0.4,
        },
      },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
      },
      copilot_node_command = 'node', -- Node.js 版本需要 18.x 以上
    }
  end,
}
