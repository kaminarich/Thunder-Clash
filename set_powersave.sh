#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh

set_governor_all "powersave"
set_gpu_powersave
clear_cache    
# Tunggu 5 menit
sleep 300
# Cek ulang apakah layar masih mati
if ! dumpsys power | grep -iq "mHoldingDisplaySuspendBlocker=true"; then
    kill_background_apps
else
    log "Layar sudah nyala, batal kill app"
fi
