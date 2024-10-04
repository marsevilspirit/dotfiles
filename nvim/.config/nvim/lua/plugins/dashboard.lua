
return{
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    dependencies = { {'nvim-tree/nvim-web-devicons'}},
    config = function()
        require('dashboard').setup {
            theme = 'hyper',
            -- config
            config = {
                header = {
                    ' ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗',
                    ' ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║',
                    ' ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║',
                    ' ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║',
                    ' ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║',
                    ' ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝',
                },
                footer = {}  --your footer
            }
        }
    end,
}
