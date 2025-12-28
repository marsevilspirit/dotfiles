return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup {
      -- 文件排序区别大小写
      sort_by = 'case_sensitive',
      view = {
        -- 侧边栏的宽度
        width = 20,
      },
      renderer = {
        -- 折叠空文件夹
        group_empty = true,
      },
      filters = {
        -- 显示隐藏文件
        dotfiles = false,
        -- 自定义过滤规则：只隐藏 .git 文件夹，不隐藏 .github
        custom = { '^\\.git$' },
      },
    }
  end,
}
