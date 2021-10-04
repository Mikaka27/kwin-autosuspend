#!/usr/bin/env bash

# Automatically suspends kwin compositor when an application is fullscreen and focused
# Should behave similar to full screen undedirect that was removed from kwin
# Modified from https://gist.github.com/Sporif/8f472bc603dac7564fa12ee0a1091498 but this one
# requires zero configuration
# Credit where credit is due

blacklist="firefox"
blacklist_path=~/.config/kwin-autosuspend/blacklist.txt
[[ -f "$blacklist_path" ]] && blacklist="$blacklist $(cat $blacklist_path)"

function handle_exit() {
    turn_effects_on
    exit 0
}
trap handle_exit SIGINT

check_kwin() {
    if ! pgrep kwin_x11 &>/dev/null; then
        echo "kwin_x11 not running"
        exit 1
    fi
}

toggle_compositing() {
    qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Suspend Compositing"
}

is_compositing_active() {
    qdbus org.kde.KWin /Compositor active
}

turn_effects_on() {
    if [[ "$(is_compositing_active)" == "false" ]]; then
        toggle_compositing
    fi
}

turn_effects_off() {
    if [[ "$(is_compositing_active)" == "true" ]]; then
        toggle_compositing
    fi
}

run_checks_on_window() {
    xprop -spy -id $1 _NET_WM_STATE |
    while read -r state; do
        is_active="$(xprop -root _NET_ACTIVE_WINDOW | grep "$1")"
        if [[ -z "$is_active" ]]; then
            fuser -k /proc/self/fd/0 &>/dev/null
            return
        fi
        is_fullscreen="$(echo "$state" | grep "_NET_WM_STATE_FULLSCREEN")"
        handle_window $is_fullscreen
    done
}

handle_window() {
    is_fullscreen=$1
    [[ -n "$is_fullscreen" ]] && turn_effects_off
    [[ -z "$is_fullscreen" ]] && turn_effects_on
}

xprop -spy -root _NET_ACTIVE_WINDOW | grep --line-buffered -o '0[xX][a-zA-Z0-9]\{7\}' |
while read -r id; do
    check_kwin
    [[ -n "$last_id" ]] && [[ "$last_id" == "$id" ]] && continue
    program_name="$(xprop -id "$id" WM_CLASS | awk '{print tolower($4)}')"
    skip=0
    for name in $blacklist; do
        if [[ \"$name\" = $program_name ]]; then
            skip=1
            break
        fi
    done
    [[ $skip -eq 0 ]] && run_checks_on_window "$id" &
    last_id=$id
done