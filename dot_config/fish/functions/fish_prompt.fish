function fish_prompt
    set -l cyan (set_color -o cyan)
    set -l normal (set_color normal)
    set -l white (set_color -o white --bold)

    set -l name $white$USER
    set -l cwd $cyan(path basename -- (prompt_pwd))/

    set -l git_info (fish_git_prompt)

    set -l dollar "$normal\$"

    echo -n -s "$name:$cwd$git_info $dollar "
end
