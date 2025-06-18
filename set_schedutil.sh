#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/mode/normal_func"
#==== [ BALANCE PROFILE SEQUENCE ] ====
flush_dns
disable_tracing_debug
fix_entropy
fix_vm_io
fix_zram
fix_cpuset
set_governor_schedutil
set_gpu_balance
fix_thermal_limit
performance_profile