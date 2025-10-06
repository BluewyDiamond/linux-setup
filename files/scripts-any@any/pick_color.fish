#!/bin/env fish

set script_name (basename (status filename))
set picked_color (hyprpicker --autocopy)

notify-send "$script_name" "<span color='$picked_color'> $picked_color 󰇘󰇘󰇘 clipboard</span>"
