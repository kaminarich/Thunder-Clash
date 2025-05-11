#!/system/bin/sh

MODDIR=${0%/*}

# Jalankan monitor game dan layar di background
sh $MODDIR/converter_game.sh &
sh $MODDIR/converter_whitelist.sh &
sh $MODDIR/monitor_screen.sh &
sh $MODDIR/monitor_game.sh &

# Tunggu boot selesai
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 10
done

# Fungsi
tweak() {
    if [ -e "$1" ]; then
        echo "$2" > "$1" && echo "Applied $2 to $1"
    fi
}

# Mali Scheduler
mali_dir=$(ls -d /sys/devices/platform/soc/*mali*/scheduling 2>/dev/null | head -n 1)
mali1_dir=$(ls -d /sys/devices/platform/soc/*mali* 2>/dev/null | head -n 1)

[ -n "$mali_dir" ] && tweak "$mali_dir/serialize_jobs" "full"
[ -n "$mali1_dir" ] && tweak "$mali1_dir/js_ctx_scheduling_mode" "1"

# Panic tweaks
tweak /sys/module/kernel/parameters/panic 0
tweak /sys/module/kernel/parameters/panic_on_warn 0
tweak /sys/module/kernel/parameters/pause_on_oops 0
tweak /proc/sys/vm/panic_on_oom 0
tweak /proc/sys/kernel/softlockup_panic 0
tweak /proc/sys/kernel/panic_on_warn 0
tweak /proc/sys/kernel/panic_on_oops 0
tweak /proc/sys/kernel/panic 0

# Hanya di service.sh karena properti tidak umum:
resetprop -n PERF_RES_NET_BT_AUDIO_LOW_LATENCY 1
resetprop -n PERF_RES_NET_WIFI_LOW_LATENCY 1
resetprop -n PERF_RES_NET_MD_WEAK_SIG_OPT 1
resetprop -n PERF_RES_NET_NETD_BOOST_UID 1
resetprop -n PERF_RES_NET_MD_HSR_MODE 1
resetprop -n PERF_RES_THERMAL_POLICY -1

# Optional jika device support:
resetprop -n persist.audio.fluence.mode endfire
resetprop -n persist.audio.vr.enable true
resetprop -n persist.audio.handset.mic digital
resetprop -n af.resampler.quality 255
resetprop -n mpq.audio.decode true