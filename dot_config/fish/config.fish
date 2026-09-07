set -l secrets_fish "$__fish_config_dir/secrets.fish"
if test -f $secrets_fish
    source $secrets_fish
end

if status is-interactive
    # Commands to run in interactive sessions can go here

    fish_config theme choose "Dracula Official"

    if type -q go
        fish_add_path --append --path (go env GOPATH)/bin
    end

    set -g fish_autosuggestion_enabled 1

    if test -f ~/.cargo/env.fish
        source ~/.cargo/env.fish
    end

    abbr s fastfetch

    if type -q zoxide
        zoxide init fish | source
        abbr cd z
    end

    if type -q eza
        abbr ls eza
        abbr ll "eza -l -g --icons"
        abbr lla "ll -a"
    end

    if type -q fzf
        fzf --fish | source
    end
end

export PATH="$HOME/.local/bin:$PATH"
fish_add_path --path "$HOME/.cargo/bin"
