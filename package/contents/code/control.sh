#!/usr/bin/env bash
#
# Control script for the Insomnia widget: manages two independent
# systemd-inhibit "holder" processes (sleep, idle) and publishes the combined
# state to a shared, append-only data file that every widget instance follows
# with `tail -F` (same multicast pattern as gamemode-status's watcher.sh).
#
# Each holder process IS the lock: while its wrapped `sleep` is alive, the
# inhibition is active; killing it (or letting a timed `sleep N` run out)
# releases it. This is deliberate - PolicyAgent's cookie-based AddInhibition
# D-Bus call releases itself the instant the calling connection closes, so a
# one-shot script can't use it to hold a lock open. A backgrounded
# systemd-inhibit process can, and `systemd-inhibit --list` can audit it.
#
# usage: control.sh start <sleep|idle> [minutes]   # 0/omitted = indefinite
#        control.sh stop  <sleep|idle>
#        control.sh sync                           # re-publish current state
set -u

BASE="${XDG_RUNTIME_DIR:-/tmp}/insomnia-$(id -u)"
DATA="$BASE/state.data"
SELF="$(readlink -f "$0")"

mkdir -p -m 700 "$BASE"

is_alive() {
    local pidfile="$1" pid
    [ -f "$pidfile" ] || return 1
    pid="$(cat "$pidfile" 2>/dev/null)"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# Re-query the authoritative state from the pidfiles (never trust a cached
# flag) and append one full snapshot line - e.g. "sleep:on|idle:off" - so
# every reader picks up the real, current combination no matter which event
# triggered the publish. Mirrors gamemode-status's watcher.sh: re-derive from
# the source of truth on every change instead of tracking deltas.
publish() {
    local s="off" i="off"
    is_alive "$BASE/sleep.pid" && s="on"
    is_alive "$BASE/idle.pid" && i="on"
    echo "sleep:${s}|idle:${i}" >> "$DATA"
}

case "${1:-}" in
    start)
        type="${2:-}"
        minutes="${3:-0}"
        case "$type" in
            sleep|idle) ;;
            *) echo "usage: $0 start <sleep|idle> [minutes]" >&2; exit 1 ;;
        esac
        pidfile="$BASE/$type.pid"

        if is_alive "$pidfile"; then
            publish   # already running - idempotent, just re-confirm state
            exit 0
        fi

        if [ "$minutes" -gt 0 ] 2>/dev/null; then
            setsid nohup systemd-inhibit --what="$type" --who="insomnia" \
                --why="user request" sleep "$((minutes * 60))" >/dev/null 2>&1 &
        else
            setsid nohup systemd-inhibit --what="$type" --who="insomnia" \
                --why="user request" sleep infinity >/dev/null 2>&1 &
        fi
        pid=$!
        disown
        echo "$pid" > "$pidfile"
        publish

        if [ "$minutes" -gt 0 ] 2>/dev/null; then
            # Detached reaper: blocks until the holder exits on its own (the
            # timer ran out), then cleans up and republishes so the widget's
            # icon flips back with no polling loop of our own. `tail --pid`
            # works across process trees - unlike shell `wait`, it doesn't
            # require the watched pid to be this process's direct child,
            # which matters once the holder above has setsid'd away.
            setsid nohup bash -c "
                tail --pid=$pid -f /dev/null 2>/dev/null
                rm -f '$pidfile'
                '$SELF' sync
            " >/dev/null 2>&1 &
            disown
        fi
        ;;

    stop)
        type="${2:-}"
        case "$type" in
            sleep|idle) ;;
            *) echo "usage: $0 stop <sleep|idle>" >&2; exit 1 ;;
        esac
        pidfile="$BASE/$type.pid"
        if is_alive "$pidfile"; then
            kill "$(cat "$pidfile")" 2>/dev/null
        fi
        rm -f "$pidfile"
        publish
        ;;

    sync)
        publish
        ;;

    *)
        echo "usage: $0 start <sleep|idle> [minutes] | stop <sleep|idle> | sync" >&2
        exit 1
        ;;
esac
