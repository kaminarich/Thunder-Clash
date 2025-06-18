#!/system/bin/sh

MODDIR=${0%/*}
GAMELIST="$MODDIR/gamelist_conv.txt"
STATE_FILE="/data/local/tmp/.game_state"
LOGFILE="/data/local/tmp/thunderclash/gamemode.txt"

mkdir -p /data/local/tmp/thunderclash
touch "$LOGFILE"

[ ! -f "$STATE_FILE" ] && echo "off" > "$STATE_FILE"

log() {
    echo "[monitor_game] $1" >> "$LOGFILE"
}

is_game_running() {
    for pkg in $(cat "$GAMELIST"); do
        if pidof "$pkg" >/dev/null; then
            echo "$pkg"
            return 0
        fi
    done
    return 1
}

PREV_STATE=$(cat "$STATE_FILE")

log "Started monitor_game.sh with initial STATE=$PREV_STATE"

while true; do
    if GAME_PKG=$(is_game_running); then
        if [ "$PREV_STATE" != "on" ]; then
            echo "on" > "$STATE_FILE"
            PREV_STATE="on"
            log "Game ON → [$GAME_PKG], applying set_performance.sh"
            sh "$MODDIR/set_performance.sh"
        fi
    else
        if [ "$PREV_STATE" != "off" ]; then
            echo "off" > "$STATE_FILE"
            PREV_STATE="off"
            log "Game OFF → applying set_schedutil.sh"
            sh "$MODDIR/set_schedutil.sh"
        fi
    fi

    sleep 10
done