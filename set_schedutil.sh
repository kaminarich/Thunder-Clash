#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh
set_governor_all "performance"
# Tunggu boot selesai
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 10
set_governor_all "schedutil"
set_gpu_powersave
thunder_freq_little 750000 800000
thunder_freq_big 800000 1100000
encore_mediatek_powersave
mtkvest_normal
corin_balanced
lite_profiles
