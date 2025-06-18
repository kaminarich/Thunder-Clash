#!/system/bin/sh
MODDIR=${0%/*}
sleep 1
# Tuning lainnya...
. "$MODDIR/mode/performance_func"
fix_thermal_limit
disable_tracing_debug
set_governor_all performance
set_gpu
fix_cpuset
performance_profile
fix_vm_io
fix_zram
fix_entropy
flush_dns