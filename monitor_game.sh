#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh

GAMELIST="$MODDIR/gamelist.txt"

is_foreground_game() {
    pkg=$(dumpsys window | grep -m 1 "mCurrentFocus" | sed 's/.* //;s/}//' | cut -d '/' -f1)
    grep -Fxq "$pkg" "$GAMELIST"
}

while true; do
    if dumpsys power | grep -iq "mHoldingDisplaySuspendBlocker=true"; then
        if is_foreground_game; then
            sh $MODDIR/set_performance.sh
        else
            sh $MODDIR/set_schedutil.sh
        fi
    fi
    sleep 5
done