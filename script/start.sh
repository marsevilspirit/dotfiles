xrandr --output DP-2 --mode 2560x1600 --rate 240.00
xrandr --output HDMI-0 --mode 2560x1440 --right-of DP-2 --rate 144.00
xrandr --output DP-5 --mode 2560x1600 --right-of HDMI-0 --rotate left --rate 144.00
feh --bg-center ~/pictures/wallpapers/wallhaven-952qod_2560x1600.png \
   ~/pictures/wallpapers/wallhaven-952qod_2560x1440.png \
   ~/pictures/wallpapers/wallhaven-952qod_1600x2560.png
