#!/bin/bash

# 终止正在运行的 bar 实例
killall -q polybar

# 等待 Polybar 完全退出
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# 启动 Polybar 实例，针对每个显示器
for monitor in $(xrandr --query | grep ' connected' | cut -d' ' -f1); do
    case $monitor in
        DP-2)
            MONITOR=$monitor polybar mybar1 2>&1 | tee -a /tmp/polybar.log & disown
            ;;
    esac
done

echo "Polybar launched on all connected monitors..."
