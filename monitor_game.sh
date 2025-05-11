#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh

GAMELIST_CONV="$MODDIR/gamelist_conv.txt"
WHITELIST_CONV="$MODDIR/whitelist_conv.txt"

is_foreground_game() {
    pkg=$(dumpsys window | grep -m 1 "mCurrentFocus" | sed 's/.* //;s/}//' | cut -d '/' -f1)
    
    # Cek apakah aplikasi yang sedang berjalan ada di dalam gamelist_conv.txt
    grep -Fxq "$pkg" "$GAMELIST_CONV"
}

is_whitelisted() {
    pkg=$(dumpsys window | grep -m 1 "mCurrentFocus" | sed 's/.* //;s/}//' | cut -d '/' -f1)
    
    # Cek apakah aplikasi yang sedang berjalan ada di dalam whitelist_conv.txt
    grep -Fxq "$pkg" "$WHITELIST_CONV"
}

while true; do
    if dumpsys power | grep -iq "mHoldingDisplaySuspendBlocker=true"; then
        if is_foreground_game; then
            sh $MODDIR/set_performance.sh
        elif is_whitelisted; then
            # Jika aplikasi ada di whitelist, jangan dimatikan atau diganggu
            continue
        else
            sh $MODDIR/set_schedutil.sh
        fi
    fi
    sleep 5
done