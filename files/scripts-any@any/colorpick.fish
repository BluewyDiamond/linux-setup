#!/usr/bin/env fish

set script_name (basename (status filename))

set hyprpicker_output (hyprpicker; or notify-send "$script_name" "Failed, status code non zero!")
wl-copy $hyprpicker_output
notify-send "$script_name" "Copied $hyprpicker_output to clipboard."
