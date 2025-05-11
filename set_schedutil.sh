#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh
# Tunggu boot selesai
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 10
done
set_governor_all "schedutil"
thunder_freq_little 750000 800000
thunder_freq_big 800000 1100000
reset_gpu_default
encore_mediatek_powersave
mtkvest_normal
corin_balanced
lite_profiles
