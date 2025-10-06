#!/usr/bin/env fish

set options "󰹑 Screenshot" \
    "󰆞 Screenshot (Region)" \
    " Color Pick" \
    " Clip"

# expected to be a number or empty
set fuzzel_output (string join \n $options | fuzzel --dmenu --index && sleep 0.5 ) # adds a delay to allow fuzzel to close
# in order to cover blank possibility
set fuzzel_output (string trim $fuzzel_output)

# nothing was selected thus quit
if test -z "$fuzzel_output"
    exit 0
end

set selected_option (math $fuzzel_output + 1)
set current_dir (dirname (realpath (status --current-filename)))

switch $selected_option
    case 1
        $current_dir/screenshot.fish
    case 2
        $current_dir/screenshot.fish partial
    case 3
        $current_dir/colorpick.fish
     case 4
        $current_dir/clip.fish
end
