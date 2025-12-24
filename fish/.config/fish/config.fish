if status is-interactive
    # Commands to run in interactive sessions can go here

    # theme: Dracula
    fish_config theme choose "Dracula Official"

    export CHEAT_CONFIG_PATH="~/.config/cheat/conf.yml"

    export PATH="$PATH:$(go env GOPATH)/bin"

	# linux config
	# export PATH="$PATH:/home/mars/.cargo/bin"

	# linux config
	# export PATH="$PATH:/home/mars/.local/share/bob/nvim-bin"

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

    # zoxide
    zoxide init fish | source
end

# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish

export PATH="$HOME/.local/bin:$PATH"

# pnpm
set -gx PNPM_HOME "/Users/mars/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Added by Antigravity
fish_add_path /Users/mars/.antigravity/antigravity/bin
