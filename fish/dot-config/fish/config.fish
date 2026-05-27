set -l secrets_fish "$HOME/.config/fish/secrets.fish"
if test -f $secrets_fish
    source $secrets_fish
end

if status is-interactive
    # Commands to run in interactive sessions can go here

    fish_config theme choose "Dracula Official"

    export PATH="$PATH:$(go env GOPATH)/bin"

    set -g fish_autosuggestion_enabled 1

    if test -f ~/.cargo/env.fish
        source ~/.cargo/env.fish
    end

    abbr s fastfetch

    if type -q zoxide
        abbr cd z
    end

    if type -q eza
        abbr ls eza
        abbr ll "eza -l -g --icons"
        abbr lla "ll -a"
    end

    fzf --fish | source
    zoxide init fish | source
end

export PATH="$HOME/.local/bin:$PATH"
