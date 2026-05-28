-- Gitsigns: git integration in the sign column
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    local gs = require 'gitsigns'

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']g', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gs.nav_hunk 'next'
      end
    end, { desc = 'Next [g]it hunk' })

    map('n', '[g', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gs.nav_hunk 'prev'
      end
    end, { desc = 'Previous [g]it hunk' })

    -- Hunk actions
    map('n', '<leader>gp', gs.preview_hunk, { desc = '[g]it [p]review hunk' })
    map('n', '<leader>gi', gs.preview_hunk_inline, { desc = '[g]it preview hunk [i]nline' })
    map('n', '<leader>gs', gs.stage_hunk, { desc = '[g]it [s]tage hunk' })
    map('n', '<leader>gr', gs.reset_hunk, { desc = '[g]it [r]eset hunk' })

    map('v', '<leader>gs', function()
      gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = '[g]it [s]tage hunk' })
    map('v', '<leader>gr', function()
      gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = '[g]it [r]eset hunk' })

    -- Buffer actions
    map('n', '<leader>gS', gs.stage_buffer, { desc = '[g]it [S]tage buffer' })
    map('n', '<leader>gR', gs.reset_buffer, { desc = '[g]it [R]eset buffer' })
    map('n', '<leader>gu', gs.undo_stage_hunk, { desc = '[g]it [u]ndo stage hunk' })

    -- Blame
    map('n', '<leader>gb', gs.blame_line, { desc = '[g]it [b]lame line' })
    map('n', '<leader>gB', function()
      gs.blame_line { full = true }
    end, { desc = '[g]it [B]lame line (full)' })

    -- Diff
    map('n', '<leader>gd', gs.diffthis, { desc = '[g]it [d]iff against index' })
    map('n', '<leader>gD', function()
      gs.diffthis '~'
    end, { desc = '[g]it [D]iff against last commit' })

    -- Toggles
    map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
    map('n', '<leader>tD', gs.toggle_deleted, { desc = '[T]oggle git show [D]eleted' })
  end,
}
