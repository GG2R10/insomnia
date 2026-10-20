#!/usr/bin/env bash
#
# Standalone toggle for binding to a global keyboard shortcut (System
# Settings -> Shortcuts -> Custom Shortcuts), independent of the widget being
# on a panel at all. It reads the same pidfiles control.sh manages and writes
# to the same state.data, so the panel widget (which just follows state.data
# with `tail -F`) picks up whatever this script does automatically - no
# separate "is the widget listening for the keybind" logic needed anywhere.
#
# usage: toggle.sh [sleep|idle|both] [minutes]
#   target defaults to "both"; minutes defaults to 0 (indefinite).
set -u

BASE="${XDG_RUNTIME_DIR:-/tmp}/insomnia-$(id -u)"
CONTROL="$(dirname "$(readlink -f "$0")")/control.sh"

target="${1:-both}"
minutes="${2:-0}"

is_alive() {
    local pidfile="$1" pid
    [ -f "$pidfile" ] || return 1
    pid="$(cat "$pidfile" 2>/dev/null)"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

case "$target" in
    sleep|idle)
        if is_alive "$BASE/$target.pid"; then
            "$CONTROL" stop "$target"
        else
            "$CONTROL" start "$target" "$minutes"
        fi
        ;;
    both)
        # Fully on only when BOTH are already active -> turn both off.
        # Otherwise, turn on whichever is missing (never relaunch one that's
        # already running).
        if is_alive "$BASE/sleep.pid" && is_alive "$BASE/idle.pid"; then
            "$CONTROL" stop sleep
            "$CONTROL" stop idle
        else
            is_alive "$BASE/sleep.pid" || "$CONTROL" start sleep "$minutes"
            is_alive "$BASE/idle.pid" || "$CONTROL" start idle "$minutes"
        fi
        ;;
    *)
        echo "usage: $0 [sleep|idle|both] [minutes]" >&2
        exit 1
        ;;
esac
