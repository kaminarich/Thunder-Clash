#!/system/bin/sh

MODDIR=${0%/*}
. $MODDIR/common.sh

set_governor_all "performance"
set_gpu_performance
encore_mediatek_perf
corin_perf
mtkvest_perf
qos_perf
gamemode