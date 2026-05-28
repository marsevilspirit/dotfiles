function ts
    set -l session_name $argv[1]

    if test -z "$session_name"
        set -l sessions (tmux ls -F "#S" 2>/dev/null)
        if test -z "$sessions"
            read -p 'echo "No sessions found. Create new session: "' session_name
        else
            # 关键修改：使用 string join \n 确保每个 Session 占用一行
            set session_name (string join \n $sessions | fzf --prompt="Select tmux session: " --height=40% --reverse)
        end
    end

    if test -z "$session_name"
        return
    end

    if test -z "$TMUX"
        tmux new-session -A -s "$session_name"
    else
        # 这里的 $session_name 建议加上双引号，防止名字中的空格导致 tmux 命令解析失败
        tmux switch-client -t "$session_name" 2>/dev/null; or tmux new-session -d -s "$session_name"; and tmux switch-client -t "$session_name"
    end
end
