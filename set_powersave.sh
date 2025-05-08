#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh

set_governor_all "powersave"
reset_gpu_default
clear_cache
encore_mediatek_powersave
