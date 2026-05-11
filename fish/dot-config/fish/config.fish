if status is-interactive
    # Commands to run in interactive sessions can go here

    # theme: Dracula
    fish_config theme choose "Dracula Official"

    export PATH="$PATH:$(go env GOPATH)/bin"

    if test -f ~/.cargo/env.fish
        source ~/.cargo/env.fish
    end

    # 取消自动补全
    set -g fish_autosuggestion_enabled 0

    # neofetch快捷键
    abbr s fastfetch
    # kitty快捷键
    abbr icat "kitty +kitten icat"
    # zoxide
    abbr cd z

    if type -q eza
        abbr ls eza
        abbr ll "eza -l -g --icons"
        abbr lla "ll -a"
    end

    # fzf
    fzf --fish | source

    zoxide init fish | source
end

# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish

export PATH="$HOME/.local/bin:$PATH"
