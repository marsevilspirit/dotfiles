if status is-interactive
    # Commands to run in interactive sessions can go here

    export CHEAT_CONFIG_PATH="~/.config/cheat/conf.yml"

    export PATH="$PATH:$(go env GOPATH)/bin"

    # 取消自动补全
    set -g fish_autosuggestion_enabled 0

    # neofetch快捷键
    abbr s neofetch
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
    # Uxplay
    abbr uxplay "sudo systemctl start avahi-daemon.service && uxplay"

    # leetcode 每日提醒
    python $HOME/utils/leetcode_notifyV2.py &

    if type -q eza 
        abbr ls eza
        abbr ll "eza -l -g --icons"
        abbr lla "ll -a"
    end

    # fzf
    fzf --fish | source

    # zoxide 
    zoxide init fish | source
end
