#!/usr/bin/env fish

set script_name (basename (status filename))
set replays_dir $HOME/media/obs
set timeout_in_seconds 2
set now_epoch_time (date +%s)

if pidof obs &>/dev/null
    set hyprctl_output (hyprctl dispatch sendshortcut ',F1, class:com.obsproject.Studio')

    # because hyprctl fail does not change the status
    if not string match -q -r ok $hyprctl_output
        notify-send "$script_name" "hyprctl => $hyprctl_output"
        exit 1
    end

    sleep $timeout_in_seconds

    # TODO: check for failure at the next line
    set found_latest_replay_pathname (command ls $replays_dir/Replay_* | sort -r | head -n 1)
    set found_latest_replay_basename (basename $found_latest_replay_pathname)

    set found_latest_replay_datetime (string replace -r -- '^Replay_([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2})-([0-9]{2})-([0-9]{2}).*' '$1 $2:$3:$4' $found_latest_replay_basename)
    if test $status -ne 0
        notify-send "$script_name" "Failed replacing string..."
    end

    set found_latest_replay_epoch_time (date -d "$found_latest_replay_datetime" +%s)
    if test $status -ne 0
        notify-send "$script_name" "Failed datetime conversion..."
    end

    if test $found_latest_replay_epoch_time -ge $now_epoch_time
        notify-send "$script_name" "Clip saved."
    else
        notify-send "$script_name" "Sent clip signal but clip not found..."
    end
else
    notify-send "$script_name" "OBS is not running... Unable to clip."
end
