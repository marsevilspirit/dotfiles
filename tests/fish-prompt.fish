test "$__fish_git_prompt_showuntrackedfiles" = true
and test "$__fish_git_prompt_showcolorhints" = true
and test "$__fish_git_prompt_show_informative_status" = true
and test "$__fish_git_prompt_color_prefix" = blue
and test "$__fish_git_prompt_color_suffix" = blue
and test "$__fish_git_prompt_color_branch" = 'yellow --bold'
or begin
    echo 'Git prompt defaults must be set during interactive startup' >&2
    exit 1
end

set -g prompt_option_events 0
function count_prompt_option_events \
        --on-variable __fish_git_prompt_showuntrackedfiles \
        --on-variable __fish_git_prompt_showcolorhints \
        --on-variable __fish_git_prompt_show_informative_status \
        --on-variable __fish_git_prompt_color_prefix \
        --on-variable __fish_git_prompt_color_suffix \
        --on-variable __fish_git_prompt_color_branch
    set -g prompt_option_events (math $prompt_option_events + 1)
end

set -g USER prompt-user
cd "$argv[1]"; or exit 1
fish_prompt
fish_prompt
test $prompt_option_events -eq 0
or begin
    printf '\nPrompt redraws triggered %s Git option events\n' $prompt_option_events >&2
    exit 1
end
