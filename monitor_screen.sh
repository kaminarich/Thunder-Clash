#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh

while true; do
    if dumpsys power | grep -iq "mHoldingDisplaySuspendBlocker=true"; then
        # Layar nyala, jangan lakukan apapun
        :
    else
        # Layar mati
        sleep 5
        sh $MODDIR/set_powersave.sh
    fi
    sleep 2
done