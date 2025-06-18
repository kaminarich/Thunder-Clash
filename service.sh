#!/system/bin/sh

MODDIR=${0%/*}

# Tunggu boot selesai
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 5
done

# Permission biar pasti jalan
chmod 0755 "$MODDIR/set_performance.sh"
chmod 0755 "$MODDIR/set_schedutil.sh"
chmod 0755 "$MODDIR/monitor_screen.sh"
chmod 0755 "$MODDIR/gamelist_conv.sh"
chmod 0755 "$MODDIR/converter_whitelist.sh"
#early start schedutil
sh "$MODDIR/set_schedutil.sh" &
# Start background daemon
sh "$MODDIR/monitor_screen.sh" &

sleep 5
DEVICE_NAME=$(getprop ro.product.name)
su -lp 2000 -c "cmd notification post -S bigtext -t 'Thunder Clash⚡' Tag 'Applied💦 at $DEVICE_NAME'" >/dev/null &
# Fungsi tweak
tweak() {
    [ -e "$1" ] && echo "$2" > "$1" && echo "Applied $2 to $1"
}

# Mali scheduler tweaks
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

# Properti performa
resetprop -n PERF_RES_NET_BT_AUDIO_LOW_LATENCY 1
resetprop -n PERF_RES_NET_WIFI_LOW_LATENCY 1
resetprop -n PERF_RES_NET_MD_WEAK_SIG_OPT 1
resetprop -n PERF_RES_NET_NETD_BOOST_UID 1
resetprop -n PERF_RES_NET_MD_HSR_MODE 1
resetprop -n PERF_RES_THERMAL_POLICY -1

# Audio props
resetprop -n persist.audio.fluence.mode endfire
resetprop -n persist.audio.vr.enable true
resetprop -n persist.audio.handset.mic digital
resetprop -n af.resampler.quality 255
resetprop -n mpq.audio.decode tru