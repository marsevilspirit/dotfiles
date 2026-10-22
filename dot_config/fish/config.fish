set -l secrets_fish "$__fish_config_dir/secrets.fish"
if test -f $secrets_fish
    source $secrets_fish
end

if status is-interactive
    # Commands to run in interactive sessions can go here

    fish_config theme choose "Dracula Official"

    set -g __fish_git_prompt_showuntrackedfiles 'true'
    set -g __fish_git_prompt_showcolorhints 'true'
    set -g __fish_git_prompt_show_informative_status 'true'
    set -g __fish_git_prompt_color_prefix blue
    set -g __fish_git_prompt_color_suffix blue
    set -g __fish_git_prompt_color_branch yellow --bold

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

while set -l local_bin_index (contains -i -- "$HOME/.local/bin" $PATH)
    set -e PATH[$local_bin_index]
end
fish_add_path --path "$HOME/.cargo/bin"
if not fish_add_path --path "$HOME/.local/bin"
    # Keep the PATH entry even before the directory exists.
    set -gx PATH "$HOME/.local/bin" $PATH
end

if test -f "$__fish_config_dir/local.fish"
    source "$__fish_config_dir/local.fish"
end
