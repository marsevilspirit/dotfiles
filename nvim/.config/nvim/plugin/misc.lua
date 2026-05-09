-- Misc plugin setups that don't need their own file

-- Guess-indent: detect tabstop and shiftwidth automatically
require('guess-indent').setup {}

-- Todo-comments: highlight TODO, FIXME, etc
require('todo-comments').setup { signs = false }

-- LuaSnip: snippet engine
require('luasnip').setup {}
