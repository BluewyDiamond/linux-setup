#!/usr/bin/env fish

set script_name (basename (status filename))
set screenshot_path (xdg-user-dir SCREENSHOTS)

if not test -d $screenshot_path
    echo "[WARNING] screenshot path not valid, defaulting to $HOME | screenshot_path={$screenshot_path}"
    set screenshot_path $HOME

    if not test -d $screenshot_path
        echo "[ERROR] screenshot path not valid, attempting to default also failed | screenshot_path={$screenshot_path}"
        exit 1
    end
end

set screenshot_pathname $screenshot_path/(date +"%Y-%m-%d_%H-%M-%S").png

if not which wayshot >/dev/null
    echo "[ERROR] unable to proceed without wayshot"
    notify-send "$script_name" "Wayshot not found..."
    exit 1
end

if string match -i -q -- $argv[1] partial
    if not which slurp >/dev/null
        echo "[ERROR] unable to proceed without slurp"
        notify-send "$script_name" "Slurp not found..."
        return
    end

    if not wayshot -f $screenshot_pathname -s (slurp)
        echo "[ERROR] wayshot error"
        notify-send "$script_name" "Wayshot error..."
        exit 1
    end

    wl-copy <$screenshot_pathname
    set result (notify-send Screenshot "$screenshot_pathname" -h STRING:"image-path":"$screenshot_pathname" --action="show_in_files=Show In Files" --action="open=Open" --action="edit=Edit")

    switch $result
        case "*show_in_files*"
            xdg-open dirname $screenshot_pathname
        case "*open*"
            xdg-open $screenshot_pathname
        case "*edit*"
            satty -f $screenshot_pathname
    end
else
    if not wayshot -f $screenshot_pathname
        echo "[ERROR] wayshot error"
        notify-send "$script_name" "Wayshot error..."
        exit 1
    end

    wl-copy <$screenshot_pathname
    set result (notify-send Screenshot "$screenshot_pathname" -h STRING:"image-path":"$screenshot_pathname" --action="show_in_files=Show In Files" --action="open=Open" --action="edit=Edit")

    switch $result
        case "*show_in_files*"
            xdg-open dirname $screenshot_pathname
        case "*open*"
            xdg-open $screenshot_pathname
        case "*edit*"
            satty -f $screenshot_pathname
    end
end
