function fish_prompt
    set -l __last_command_exit_status $status

    set -l cyan (set_color -o cyan)
    set -l yellow (set_color -o yellow)
    set -l red (set_color -o red)
    set -l blue (set_color -o blue)
    set -l normal (set_color normal)
    set -l white (set_color -o white --bold)

    set -l name $white(whoami)
    set -l cwd $cyan(basename (prompt_pwd))/

    set -g __fish_git_prompt_showuntrackedfiles 'true'
    set -g __fish_git_prompt_showcolorhints 'true'
    set -g __fish_git_prompt_show_informative_status 'true'
    set -g __fish_git_prompt_color_prefix blue
    set -g __fish_git_prompt_color_suffix blue
    set -g __fish_git_prompt_color_branch yellow --bold
    set -l git_info (fish_git_prompt)

    set -l dollar "$normal\$"

    echo -n -s "$name $cwd$git_info $dollar "
end
