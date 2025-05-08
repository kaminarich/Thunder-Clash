#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh

set_governor_all "schedutil"
reset_gpu_default
encore_mediatek_normal
mtkvest_normal
corin_balanced
lite_profiles