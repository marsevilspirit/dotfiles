if status is-interactive
    # Commands to run in interactive sessions can go here

    # theme: Dracula
    fish_config theme choose "Dracula Official"

    export CHEAT_CONFIG_PATH="~/.config/cheat/conf.yml"

    export PATH="$PATH:$(go env GOPATH)/bin"

    # export PATH="$PATH:/home/mars/utils/cmake-3.26/bin"

    export PATH="$PATH:/home/mars/.cargo/bin"

    export PATH="$PATH:/home/mars/.local/share/bob/nvim-bin"

    # export https_proxy=http://127.0.0.1:20172 http_proxy=http://127.0.0.1:20171 all_proxy=socks5://127.0.0.1:20170

    # 取消自动补全
    set -g fish_autosuggestion_enabled 0

    # neofetch快捷键
    abbr s fastfetch
    # kitty快捷键
    abbr icat "kitty +kitten icat"
    # zoxide
    abbr cd z
    # bat
    abbr cat bat
    # duf
    abbr df duf
    # nvim
    abbr nv nvim
    # exit
    abbr :q exit
	# playerctl
	abbr mp playerctl

    if type -q eza
        abbr ls eza
        abbr ll "eza -l -g --icons"
        abbr lla "ll -a"
    end

    # fzf
    fzf --fish | source

    # zoxide
    zoxide init fish | source

    # thefuck
    thefuck --alias | source
end

# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish
