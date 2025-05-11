#!/system/bin/sh
# Atur frekuensi untuk CPU 0–5 (LITTLE)
set_governor_all() {
    target="$1"
    state_file="/data/adb/modules/ThunderClash/.last_governor"
    current=""

    if [ -d /sys/devices/system/cpu/cpufreq/policy0 ]; then
        # Gunakan path policy*
        current=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null)
        if [ "$current" != "$target" ]; then
            for policy in /sys/devices/system/cpu/cpufreq/policy*; do
                echo "$target" > "$policy/scaling_governor" 2>/dev/null && \
                log "Set $policy to $target"
            done
            echo "$target" > "$state_file"
            su -lp 2000 -c "cmd notification post -S bigtext -t 'ThunderClash' Tag '$target Mode ON (policy)'"
        else
            log "Governor already set to $target, no change."
        fi
    else
        log "CPU policy path not found."
    fi
}
thunder_freq_little() {
    MIN="$1"
    MAX="$2"
    log "Set LITTLE cores (CPU0-5) freq: min=$MIN max=$MAX"
    for cpu in /sys/devices/system/cpu/cpu[0-5]; do
        [ -e "$cpu/cpufreq/scaling_min_freq" ] && echo "$MIN" > "$cpu/cpufreq/scaling_min_freq"
        [ -e "$cpu/cpufreq/scaling_max_freq" ] && echo "$MAX" > "$cpu/cpufreq/scaling_max_freq"
        log "  ${cpu##*/}: $MIN - $MAX"
    done
}

# Atur frekuensi untuk CPU 6–7 (BIG)
thunder_freq_big() {
    MIN="$1"
    MAX="$2"
    log "Set BIG cores (CPU6-7) freq: min=$MIN max=$MAX"
    for cpu in /sys/devices/system/cpu/cpu6 /sys/devices/system/cpu/cpu7; do
        [ -e "$cpu/cpufreq/scaling_min_freq" ] && echo "$MIN" > "$cpu/cpufreq/scaling_min_freq"
        [ -e "$cpu/cpufreq/scaling_max_freq" ] && echo "$MAX" > "$cpu/cpufreq/scaling_max_freq"
        log "  ${cpu##*/}: $MIN - $MAX"
    done
}
gamemode() {
    GAMELIST="$MODDIR/gamelist_conv.txt"
    WHITELIST="$MODDIR/whitelist_conv.txt"
    log "Killing background apps except those in gamelist or whitelist"

    # Ambil semua package user
    for pkg in $(cmd package list packages -3 | cut -f2 -d:); do
        # Lewati jika ada di GAMELIST atau WHITELIST
        if grep -Fxq "$pkg" "$GAMELIST" 2>/dev/null || grep -Fxq "$pkg" "$WHITELIST" 2>/dev/null; then
            log "Skipped (whitelisted): $pkg"
            continue
        fi
        # Coba force-stop
        am force-stop "$pkg" && log "Killed: $pkg"
    done
}
#set_governor_all() {
    #target="$1"
    #state_file="/data/adb/modules/ThunderClash/.last_governor"
    #current=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

    #if [ "$current" != "$target" ]; then
        #for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
            #echo "$target" > "$cpu/cpufreq/scaling_governor"
        #done

        #echo "$target" > "$state_file"

        # Kirim notifikasi hanya saat terjadi perubahan
        #su -lp 2000 -c "cmd notification post -S bigtext -t 'ThunderClash' Tag '$target Mode ON'"
    #fi
#}

set_gpu_performance() {
    echo performance > /sys/class/devfreq/13000000.mali/governor
    #kerneltweak
    # Percepat respons scheduler
echo 1000000 > /proc/sys/kernel/sched_latency_ns
echo 500000 > /proc/sys/kernel/sched_min_granularity_ns
echo 100000 > /proc/sys/kernel/sched_wakeup_granularity_ns

# Percepat migrasi antar core
echo 50000 > /proc/sys/kernel/sched_migration_cost_ns

# Matikan batasan realtime tasks biar thread game ga ke-throttle
echo -1 > /proc/sys/kernel/sched_rt_runtime_us

# Naikkan utilitas minimum & maksimum (untuk freq scaling cepat)
echo 1024 > /proc/sys/kernel/sched_util_clamp_max
echo 128 > /proc/sys/kernel/sched_util_clamp_min
# Kunci GPU di OPP tertinggi (biasanya index 0 = max freq)
tweak 0 /proc/gpufreqv2/fix_target_opp_index

# Pastikan Aging Mode dimatikan (biar ga diturunin frekuensi karena estimasi umur)
tweak 0 /proc/gpufreqv2/aging_mode

# Set GPM mode ke mode manual/performance (0 = default, 1 = manual override)
tweak 1 /proc/gpufreqv2/gpm_mode

# Disable limit table (biar ga dilimit volt/freq secara dinamis)
[ -f /proc/gpufreqv2/limit_table ] && echo 0 > /proc/gpufreqv2/limit_table
#minimal gangguan I/O
echo 0 0 0 0 > /proc/sys/kernel/printk
echo 0 > /sys/class/devfreq/13000000.mali/power
echo on > /sys/class/devfreq/13000000.mali/power/control
# Pastikan GPU tidak dibatasi oleh buffer penuh
echo 0 > /sys/class/devfreq/13000000.mali/enable
}
set_gpu_powersave() {
    echo powersave > /sys/class/devfreq/13000000.mali/governor

    # Reset scheduler tweaks ke default konservatif
    echo 20000000 > /proc/sys/kernel/sched_latency_ns
    echo 4000000  > /proc/sys/kernel/sched_min_granularity_ns
    echo 2000000  > /proc/sys/kernel/sched_wakeup_granularity_ns
    echo 500000   > /proc/sys/kernel/sched_migration_cost_ns
    echo 950000   > /proc/sys/kernel/sched_rt_runtime_us

    # Kembalikan clamp ke default (dinamis)
    echo 1024 > /proc/sys/kernel/sched_util_clamp_max
    echo 0    > /proc/sys/kernel/sched_util_clamp_min

    # Gunakan OPP paling rendah (biasanya index tertinggi = freq paling rendah)
    tweak 5 /proc/gpufreqv2/fix_target_opp_index  # Sesuaikan dengan jumlah OPP di device Anda

    # Aktifkan aging_mode kembali (biarkan kernel optimasi daya)
    tweak 1 /proc/gpufreqv2/aging_mode

    # Gunakan GPM mode default
    tweak 0 /proc/gpufreqv2/gpm_mode

    # Aktifkan kembali limit_table jika tersedia
    [ -f /proc/gpufreqv2/limit_table ] && echo 1 > /proc/gpufreqv2/limit_table

    # Biarkan kernel mengatur power control
    echo auto > /sys/class/devfreq/13000000.mali/power/control
    echo 1 > /sys/class/devfreq/13000000.mali/enable

    # Aktifkan kembali printk untuk debug minimal
    echo 3 4 1 3 > /proc/sys/kernel/printk
}
qos_perf() {
    tweak 1 /sys/devices/platform/11bb00.qos/qos/qos_bound_enable || true
    tweak 0 /sys/devices/platform/11bb00.qos/qos/qos_bound_log_enable || true
    tweak 0 /sys/devices/platform/11bb00.qos/qos/qos_bound_stress_enable || true
    
    echo 1 > /proc/gpufreqv2/fix_custom_freq_volt
    echo 0 > /proc/gpufreqv2/fix_target_opp_index
    # Disable VSYNC untuk bebas mencapai framerate tinggi
echo 0 > /sys/class/graphics/fb0/disable_vsync

# Atau set ke refresh rate yang lebih tinggi (contoh untuk 120Hz)
echo 120 > /sys/class/graphics/fb0/vsync_rate
}
# MediaTek Battery Saver Mode
lite_profiles() {
    # Aktifkan mode efisiensi kerja kernel jika tersedia
    [ -f /sys/module/workqueue/parameters/power_efficient ] && echo "Y" > /sys/module/workqueue/parameters/power_efficient
    [ -f /sys/module/workqueue/parameters/disable_numa ] && echo "Y" > /sys/module/workqueue/parameters/disable_numa

    # Set DVFSRC governor to powersave
    if [ -f "/sys/class/devfreq/mtk-dvfsrc-devfreq/governor" ]; then
        echo "powersave" > "/sys/class/devfreq/mtk-dvfsrc-devfreq/governor"
    fi

    for path in /sys/devices/platform/soc/*.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor; do
        [ -f "$path" ] && echo "powersave" > "$path"
    done

    # Enable thermal, battery, and power policies; disable SYS_BOOST
    if [ -f /proc/ppm/policy_status ]; then
        for idx in $(grep -E 'FORCE_LIMIT|PWR_THRO|THERMAL|USER_LIMIT' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
            echo "$idx 1" > /proc/ppm/policy_status
        done
        for idx in $(grep -E 'SYS_BOOST' /proc/ppm/policy_status | awk -F'[][]' '{print $2}'); do
            echo "$idx 0" > /proc/ppm/policy_status
        done
    fi

    # Revert GED parameters to balanced/default
    while IFS=' ' read -r param value; do
        GED_PARAM_PATH="/sys/module/ged/parameters/$param"
        [ -f "$GED_PARAM_PATH" ] && echo "$value" > "$GED_PARAM_PATH"
    done <<EOF
ged_smart_boost 0
boost_upper_bound 75
enable_gpu_boost 0
enable_cpu_boost 0
ged_boost_enable 0
boost_gpu_enable 0
gpu_dvfs_enable 1
gx_frc_mode 0
gx_dfps 0
gx_force_cpu_boost 0
gx_boost_on 0
gx_game_mode 0
gx_3D_benchmark_on 0
gx_fb_dvfs_margin 10
gx_fb_dvfs_threshold 80
gpu_loading 30000
cpu_boost_policy 0
boost_extra 0
is_GED_KPI_enabled 1
ged_force_mdp_enable 0
force_fence_timeout_dump_enable 1
gpu_idle 1
EOF

    # Re-enable GPU power limiters
    if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
        for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
            echo "$setting 0" > /proc/gpufreq/gpufreq_power_limited
        done
    fi
}
encore_mediatek_normal() {
	# PPM policies
	if [ -d /proc/ppm ]; then
		grep -E "$PPM_POLICY" /proc/ppm/policy_status | while read -r row; do
			tweak "${row:1:1} 1" /proc/ppm/policy_status
		done
	fi

	# MTK Power and CCI mode
	tweak 0 /proc/cpufreq/cpufreq_cci_mode
	tweak 0 /proc/cpufreq/cpufreq_power_mode
	
	# DDR Boost mode
	tweak 0 /sys/devices/platform/boot_dramboost/dramboost/dramboost
	
	# EAS/HMP Switch
	tweak 1 /sys/devices/system/cpu/eas/enable

	# GPU Frequency
	if [ -d /proc/gpufreq ]; then
		write 0 /proc/gpufreq/gpufreq_opp_freq 2>/dev/null
	elif [ -d /proc/gpufreqv2 ]; then
		write -1 /proc/gpufreqv2/fix_target_opp_index
	fi

	# GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			tweak "$setting 0" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Enable Power Budget management for new 5.x mtk kernels
	tweak "stop 0" /proc/pbm/pbm_stop

	# Enable battery current limiter
	tweak "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# DRAM Frequency
	write -1 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
	write -1 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
	devfreq_unlock /sys/class/devfreq/mtk-dvfsrc-devfreq

	# Eara Thermal
	tweak 1 /sys/kernel/eara_thermal/enable
}
encore_mediatek_powersave() {
	# MTK CPU Power mode to low power
	tweak 1 /proc/cpufreq/cpufreq_power_mode

	# GPU Frequency
	if [ -d /proc/gpufreq ]; then
		gpu_freq=$(sed -n 's/.*freq = \([0-9]\{1,\}\).*/\1/p' /proc/gpufreq/gpufreq_opp_dump | sort -n | head -n 1)
		tweak "$gpu_freq" /proc/gpufreq/gpufreq_opp_freq
	elif [ -d /proc/gpufreqv2 ]; then
		min_gpufreq_index=$(awk -F'[][]' '{print $2}' /proc/gpufreqv2/gpu_working_opp_table | sort -n | tail -1)
		tweak "$min_gpufreq_index" /proc/gpufreqv2/fix_target_opp_index
	fi
}
# Fungsi untuk kill semua background apps user (non-system)
kill_background_apps() {
    WHITELIST="/data/adb/modules/ThunderClash/whitelist_conv.txt"
    log "Killing background apps (with whitelist)..."

    # Ambil semua package yang sedang jalan (dari dumpsys atau ps)
    for pkg in $(cmd package list packages -3 | cut -f2 -d:); do
        # Lewati jika ada di whitelist
        grep -qx "$pkg" "$WHITELIST" 2>/dev/null && {
            log "Skipped (whitelisted): $pkg"
            continue
        }
        # Coba force-stop
        am force-stop "$pkg" && log "Killed: $pkg"
    done
}
clear_cache() {
    sync
    echo 3 > /proc/sys/vm/drop_caches
}
# All Encore Performance Script
encore_mediatek_perf() {
    # PPM policies
	if [ -d /proc/ppm ]; then
		grep -E "$PPM_POLICY" /proc/ppm/policy_status | while read -r row; do
			tweak "${row:1:1} 0" /proc/ppm/policy_status
		done
	fi

	# MTK Power and CCI mode
	tweak 1 /proc/cpufreq/cpufreq_cci_mode
	tweak 3 /proc/cpufreq/cpufreq_power_mode

	# DDR Boost mode
	tweak 1 /sys/devices/platform/boot_dramboost/dramboost/dramboost

	# EAS/HMP Switch
	tweak 0 /sys/devices/system/cpu/eas/enable


	# Disable GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			tweak "$setting 1" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Disable battery current limiter
	tweak "stop 1" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# DRAM Frequency
	tweak 0 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
	tweak 0 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
	devfreq_max_perf /sys/class/devfreq/mtk-dvfsrc-devfreq

	# Eara Thermal
	tweak 0 /sys/kernel/eara_thermal/enable
}
corin_perf() {
# Supposed Only Availabe in Transsion Devices 
if [ -e /proc/trans_scheduler/enable ]; then
tweak 0 /proc/trans_scheduler/enable
fi

# Not Every Device Have
if [ -e /proc/game_state ]; then
tweak 1 /proc/game_state
fi

# MALI GPU Only
if [ -e /sys/class/misc/mali0/device/power_policy ]; then
tweak always_on /sys/class/misc/mali0/device/power_policy
fi

# Memory Optimization | Older Kernel May Not Have
if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    for memtweak in /sys/kernel/mm/transparent_hugepage; do
        tweak always "$memtweak/enabled"
        tweak always "$memtweak/shmem_enabled"
    done
fi

# RAM Tweaks | All Devices Have
for ramtweak in /sys/block/ram*/bdi;do
    tweak 2048 $ramtweak/read_ahead_kb
done

# Supposed Only Availabe in MTKS CPU
if [ -e /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode ]; then
    tweak 1 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode
fi

if [ -e /sys/class/misc/mali0/device/js_ctx_scheduling_mode ]; then
    tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
fi

if [ -e /sys/module/task_turbo/parameters/feats ]; then
    tweak -1 /sys/module/task_turbo/parameters/feats
fi

# Swappiness Tweaks | All Devices Have
for vim_mem in /dev/memcg; do
tweak 30 "$vim_mem/memory.swappiness"
tweak 30 "$vim_mem/apps/memory.swappiness"
tweak 55 "$vim_mem/system/memory.swappiness"
done 

# CPU Set & CTL Tweaks | All Devices Have
# To Do: Make CPU Universal

for cpuset_tweak in /dev/cpuset; do
    tweak 0-7 $cpuset_tweak/cpus
    tweak 0-7 $cpuset_tweak/background/cpus
    tweak 0-3 $cpuset_tweak/system-background/cpus
    tweak 0-7 $cpuset_tweak/foreground/cpus
    tweak 0-7 $cpuset_tweak/top-app/cpus
    tweak 0-3 $cpuset_tweak/restricted/cpus
    tweak 0-7 $cpuset_tweak/camera-daemon/cpus
    tweak 0 $cpuset_tweak/memory_pressure_enabled
    tweak 0 $cpuset_tweak/sched_load_balance
    tweak 0 $cpuset_tweak/foreground/sched_load_balance
    tweak 0 $cpuset_tweak/sched_load_balance
    tweak 0 $cpuset_tweak/foreground-l/sched_load_balance
    tweak 0 $cpuset_tweak/dex2oat/sched_load_balance
done

for cpuctl_tweak in /dev/cpuctl; do 
    tweak 1 $cpuctl_tweak/rt/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/foreground/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive
done

# From Celestial Tweaks
# Supoosed only Helio G series who use gpufreq
if [ -d /proc/gpufreq ]; then   
for celes_gpu in /proc/gpufreq
    do
    tweak 1 $celes_gpu/gpufreq_limited_thermal_ignore
    tweak 1 $celes_gpu/gpufreq_limited_oc_ignore
    tweak 1 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
    tweak 1 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
    tweak 0 $celes_gpu/gpufreq_fixed_freq_volt
    tweak 0 $celes_gpu/gpufreq_opp_stress_test
    tweak 0 $celes_gpu/gpufreq_power_dump
    tweak 0 $celes_gpu/gpufreq_power_limited
done
fi

# Tweaks for kernel | Supposed All Devices Have
for celes_kernel in /proc/sys/kernel
    do
    tweak 1 $celes_kernel/sched_sync_hint_enable
done


# PowerVR Tweaks

if [ -d "/sys/module/pvrsrvkm/parameters" ]; then

    for powervr_tweaks in /sys/module/pvrsrvkm/parameters 
        do
    tweak 2 $powervr_tweaks/gpu_power
    tweak 256 $powervr_tweaks/HTBufferSizeInKB
    tweak 0 $powervr_tweaks/DisableClockGating
    tweak 2 $powervr_tweaks/EmuMaxFreq
    tweak 1 $powervr_tweaks/EnableFWContextSwitch
    tweak 0 $powervr_tweaks/gPVRDebugLevel
    tweak 1 $powervr_tweaks/gpu_dvfs_enable
    done
fi

if [ -d "/sys/kernel/debug/pvr/apphint" ]; then

    for powervr_apphint in /sys/kernel/debug/pvr/apphint
        do
    tweak 1 $powervr_apphint/CacheOpConfig
    tweak 512 $powervr_apphint/CacheOpUMKMThresholdSize
    tweak 0 $powervr_apphint/EnableFTraceGPU
    tweak 2 $powervr_apphint/HTBOperationMode
    tweak 1 $powervr_apphint/TimeCorrClock
    tweak 0 $powervr_apphint/0/DisableFEDLogging
    tweak 0 $powervr_apphint/0/EnableAPM
    done
fi

# Snapdragon Tweaks 

if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
    for kgsl_tweak in /sys/class/kgsl/kgsl-3d0
        do
    tweak 0 $kgsl_tweak/thermal_pwrlevel
    tweak 0 $kgsl_tweak/force_bus_on
    # tweak 0 $kgsl_tweak/force_clk_on (Disable duplicate)
    tweak 0 $kgsl_tweak/force_no_nap
    tweak 0 $kgsl_tweak/force_rail_on
    tweak 0 $kgsl_tweak/throttling
    done
fi

# Mediatek

if [ -d "/sys/kernel/debug/fpsgo/common" ]; then
    tweak "100 120 0" /sys/kernel/debug/fpsgo/common/gpu_block_boost
fi

# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 1 "$queue/rq_affinity"

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 1
settings put secure low_priority 0

# From MTKVest

cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true

# From Corin 
cmd looper_stats disable

# Power Save Mode Off
settings put global low_power 0
}
mtkvest_perf() {

tweak "0"  /proc/mtk_lpm/lpm/rc/syspll/enable
tweak "0"  /proc/mtk_lpm/lpm/rc/dram/enable
tweak "0"  /proc/mtk_lpm/lpm/rc/cpu-buck-ldo/enable
tweak "0"  /proc/mtk_lpm/lpm/rc/bus26m/enable



# Configure GED HAL settings
if [ -d /sys/kernel/ged/hal ]; then
    tweak 2  "/sys/kernel/ged/hal/loading_base_dvfs_step"
    tweak 1  "/sys/kernel/ged/hal/loading_stride_size"
    tweak 16  "/sys/kernel/ged/hal/loading_window_size"
fi


tweak "100"  /sys/kernel/ged/hal/gpu_boost_level

# Disable Dynamic Clock Management
tweak "disable 0xFFFFFFF"  /sys/dcm/dcm_state



chmod 644 /proc/mtk_lpm/suspend/suspend_state
tweak "mtk_suspend 0"  /proc/mtk_lpm/suspend/suspend_state  
tweak "kernel_suspend 0"  /proc/mtk_lpm/suspend/suspend_state  

tweak "2"  /proc/mtk_lpm/cpuidle/control/armpll_mode
tweak "2"  /proc/mtk_lpm/cpuidle/control/buck_mode
tweak "0"  /proc/mtk_lpm/cpuidle/cpc/auto_off


tweak "100 7 0"  /proc/mtk_lpm/cpuidle/state/enabled

# 
tweak 100 7 200  /proc/mtk_lpm/cpuidle/state/latency  


# Workqueue settings
tweak "N"  /sys/module/workqueue/parameters/power_efficient
tweak "N"  /sys/module/workqueue/parameters/disable_numa

# Disable duplicate
# tweak "0"  /sys/kernel/eara_thermal/enable

tweak "0"  /sys/devices/system/cpu/eas/enable

tweak "1"  /sys/devices/system/cpu/cpu2/online
tweak "1"  /sys/devices/system/cpu/cpu3/online

# Power level settings
for pl in /sys/devices/system/cpu/perf; do
    tweak "1"  "$pl/gpu_pmu_enable"
    tweak "1"  "$pl/fuel_gauge_enable"
    tweak "1"  "$pl/enable"
    tweak "1"  "$pl/charger_enable"
done


for path in /sys/devices/platform/*.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp; do
    if [ -f "$path" ]; then
        tweak "0"  "$path"
    fi
done
for path in /sys/class/devfreq/mtk-dvfsrc-devfreq/governor; do
    if [ -f "$path" ]; then
        tweak "performance"  "$path"
    fi
done

# 
# Power Policy GPU
tweak "always_on"  /sys/class/misc/mali0/device/power_policy

# 

# Scheduler settings
tweak "0"  /proc/sys/kernel/perf_cpu_time_max_percent
tweak "0"  /proc/sys/kernel/perf_event_max_contexts_per_stack
tweak "0"  /proc/sys/kernel/sched_energy_aware
tweak "300000"  /proc/sys/kernel/perf_event_max_sample_rate

# Performance Manager
tweak "1"  /proc/perfmgr/syslimiter/syslimiter_force_disable


tweak "8 0 0"  /proc/gpufreq/gpufreq_limit_table

# MTK FPSGo advanced parameters
for param in adjust_loading boost_affinity boost_LR gcc_hwui_hint; do
    tweak "1"  "/sys/module/mtk_fpsgo/parameters/$param"
done

ged_params="ged_smart_boost 1
boost_upper_bound 100
enable_gpu_boost 1
enable_cpu_boost 1
ged_boost_enable 1
boost_gpu_enable 1
gpu_dvfs_enable 1
gx_frc_mode 1
gx_dfps 1
gx_force_cpu_boost 1
gx_boost_on 1
gx_game_mode 1
gx_3D_benchmark_on 1
gx_fb_dvfs_margin 100
gx_fb_dvfs_threshold 100
gpu_loading 100000
cpu_boost_policy 1
boost_extra 1
is_GED_KPI_enabled 0
ged_force_mdp_enable 1
force_fence_timeout_dump_enable 0
gpu_idle 0"

tweak "$ged_params" | while read -r param value; do
    tweak "$value"  "/sys/module/ged/parameters/$param"
done

tweak 100  /sys/module/mtk_fpsgo/parameters/uboost_enhance_f
tweak 0  /sys/module/mtk_fpsgo/parameters/isolation_limit_cap
tweak "1"  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 1  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 1  /sys/pnpmgr/install
}

mtkvest_normal() {

tweak "mtk_suspend 0"  /proc/mtk_lpm/suspend/suspend_state  
tweak "kernel_suspend 1"  /proc/mtk_lpm/suspend/suspend_state  

# GPU Power Settings
tweak "coarse_demand"  /sys/class/misc/mali0/device/power_policy

tweak "1"  /proc/mtk_lpm/lpm/rc/syspll/enable
tweak "1"  /proc/mtk_lpm/lpm/rc/dram/enable
tweak "1"  /proc/mtk_lpm/lpm/rc/cpu-buck-ldo/enable
tweak "1"  /proc/mtk_lpm/lpm/rc/bus26m/enable

tweak "0"  /sys/kernel/ged/hal/gpu_boost_level

# Configure GED HAL settings
if [ -d /sys/kernel/ged/hal ]; then
    tweak 4  "/sys/kernel/ged/hal/loading_base_dvfs_step"
    tweak 2  "/sys/kernel/ged/hal/loading_stride_size"
    tweak 8  "/sys/kernel/ged/hal/loading_window_size"
fi

# Enable Dynamic Clock Management
tweak "restore 0xFFFFFFF"  /sys/dcm/dcm_state


tweak "2"  /proc/mtk_lpm/cpuidle/control/armpll_mode
tweak "2"  /proc/mtk_lpm/cpuidle/control/buck_mode
tweak "1"  /proc/mtk_lpm/cpuidle/cpc/auto_off

tweak "100 7 1"  /proc/mtk_lpm/cpuidle/state/enabled
  
tweak 100 7 20000  /proc/mtk_lpm/cpuidle/state/latency  


# Workqueue settings
tweak "Y"  /sys/module/workqueue/parameters/power_efficient
tweak "Y"  /sys/module/workqueue/parameters/disable_numa

# Disable Duplicate
# tweak "1"  /sys/kernel/eara_thermal/enable
tweak "1"  /sys/devices/system/cpu/eas/enable


# Power level settings
for pl in /sys/devices/system/cpu/perf; do
    tweak "0"  "$pl/gpu_pmu_enable"
    tweak "0"  "$pl/fuel_gauge_enable"
    tweak "0"  "$pl/enable"
    tweak "1"  "$pl/charger_enable"
done
for path in /sys/devices/platform/*.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp; do
    if [ -f "$path" ]; then
        tweak "-1"  "$path"
    fi
done
for path in /sys/class/devfreq/mtk-dvfsrc-devfreq/governor; do
    if [ -f "$path" ]; then
        tweak "userspace"  "$path"
    fi
done

tweak "1"  /proc/cpufreq/cpufreq_sched_disable


tweak "0"  /proc/perfmgr/syslimiter/syslimiter_force_disable

# Disable Duplicate
# tweak "stop 0"  /proc/mtk_batoc_throttling/battery_oc_protect_stop

tweak "40"  /proc/sys/kernel/perf_cpu_time_max_percent
tweak "6"  /proc/sys/kernel/perf_event_max_contexts_per_stack
tweak "1"  /proc/sys/kernel/sched_energy_aware
tweak "100000"  /proc/sys/kernel/perf_event_max_sample_rate


# MTK FPSGo advanced parameters
for param in boost_affinity boost_LR gcc_hwui_hint; do
    tweak "0"  "/sys/module/mtk_fpsgo/parameters/$param"
done

# GED parameters
ged_params="ged_smart_boost 0
boost_upper_bound 0
enable_gpu_boost 0
enable_cpu_boost 0
ged_boost_enable 0
boost_gpu_enable 0
gpu_dvfs_enable 1
gx_frc_mode 0
gx_dfps 0
gx_force_cpu_boost 0
gx_boost_on 0
gx_game_mode 0
gx_3D_benchmark_on 0
gx_fb_dvfs_margin 0
gx_fb_dvfs_threshold 0
gpu_loading 0
cpu_boost_policy 0
boost_extra 0
is_GED_KPI_enabled 1
ged_force_mdp_enable 0
force_fence_timeout_dump_enable 0
gpu_idle 0"

tweak "$ged_params" | while read -r param value; do
    tweak "$value"  "/sys/module/ged/parameters/$param"
done
tweak 25  /sys/module/mtk_fpsgo/parameters/uboost_enhance_f
tweak 1  /sys/module/mtk_fpsgo/parameters/isolation_limit_cap
tweak "0"  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 0  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 0  /sys/pnpmgr/install
}
corin_balanced() {
# Supposed Only Availabe in Transsion Devices 
if [ -e /proc/trans_scheduler/enable ]; then
tweak 1 /proc/trans_scheduler/enable
fi

# Not Every Device Have
if [ -e /proc/game_state ]; then
tweak 0 /proc/game_state
fi

# MALI GPU Only
if [ -e /sys/class/misc/mali0/device/power_policy ]; then
tweak coarse_demand /sys/class/misc/mali0/device/power_policy
fi

# Memory Optimization | Older Kernel May Not Have
if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    for memtweak in /sys/kernel/mm/transparent_hugepage; do
        tweak madvise "$memtweak/enabled"
        tweak madvise "$memtweak/shmem_enabled"
    done
fi

# RAM Tweaks | All Devices Have
for ramtweak in /sys/block/ram*/bdi;do
    tweak 1024 $ramtweak/read_ahead_kb
done

# Supposed Only Availabe in MTKS CPU
if [ -e /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode ]; then
    tweak 1 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode
fi

if [ -e /sys/class/misc/mali0/device/js_ctx_scheduling_mode ]; then
    tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
fi

if [ -e /sys/module/task_turbo/parameters/feats ]; then
    tweak -1 /sys/module/task_turbo/parameters/feats
fi

# Swappiness Tweaks | All Devices Have
for vim_mem in /dev/memcg; do
tweak 60 "$vim_mem/memory.swappiness"
tweak 60 "$vim_mem/apps/memory.swappiness"
tweak 60 "$vim_mem/system/memory.swappiness"
done 

# CPU Set & CTL Tweaks | All Devices Have
# To Do: Make CPU Universal

for cpuset_tweak in /dev/cpuset;do
        tweak 0-7 $cpuset_tweak/cpus
        tweak 0-3 $cpuset_tweak/background/cpus
        tweak 0-3 $cpuset_tweak/system-background/cpus
        tweak 0-7 $cpuset_tweak/foreground/cpus
        tweak 0-7 $cpuset_tweak/top-app/cpus
        tweak 0-3 $cpuset_tweak/restricted/cpus
        tweak 0-3 $cpuset_tweak/camera-daemon/cpus
        tweak 1 $cpuset_tweak/memory_pressure_enabled
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground/sched_load_balance
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground-l/sched_load_balance
        tweak 1 $cpuset_tweak/dex2oat/sched_load_balance
    done


for cpuctl_tweak in /dev/cpuctl; do 
        tweak 0 $cpuctl_tweak/rt/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive
    done
# From Celestial Tweaks
# Supoosed only Helio G series who use gpufreq

if [ -d "/proc/gpufreq" ]; then
for celes_gpu in /proc/gpufreq
    do
    tweak 0 $celes_gpu/gpufreq_limited_thermal_ignore
    tweak 0 $celes_gpu/gpufreq_limited_oc_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
    tweak 1 $celes_gpu/gpufreq_fixed_freq_volt
    tweak 1 $celes_gpu/gpufreq_opp_stress_test
    tweak 1 $celes_gpu/gpufreq_power_dump
    tweak 1 $celes_gpu/gpufreq_power_limited
done
fi


# Tweaks for kernel | Supposed All Devices Have
for celes_kernel in /proc/sys/kernel
    do
    tweak 0 $celes_kernel/sched_sync_hint_enable
done

# PowerVR Tweaks

if [ -d "/sys/module/pvrsrvkm/parameters" ]; then

    for powervr_tweaks in /sys/module/pvrsrvkm/parameters 
        do
    tweak 0 $powervr_tweaks/gpu_power
    tweak 128 $powervr_tweaks/HTBufferSizeInKB
    tweak 1 $powervr_tweaks/DisableClockGating
    tweak 0 $powervr_tweaks/EmuMaxFreq
    tweak 0 $powervr_tweaks/EnableFWContextSwitch
    tweak 1 $powervr_tweaks/gPVRDebugLevel
    tweak 0 $powervr_tweaks/gpu_dvfs_enable
    done
fi

if [ -d "/sys/kernel/debug/pvr/apphint" ]; then

    for powervr_apphint in /sys/kernel/debug/pvr/apphint
        do
    tweak 0 $powervr_apphint/CacheOpConfig
    tweak 256 $powervr_apphint/CacheOpUMKMThresholdSize
    tweak 1 $powervr_apphint/EnableFTraceGPU
    tweak 0 $powervr_apphint/HTBOperationMode
    tweak 0 $powervr_apphint/TimeCorrClock
    tweak 1 $powervr_apphint/0/DisableFEDLogging
    tweak 1 $powervr_apphint/0/EnableAPM
    done
fi

if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
    for kgsl_tweak in /sys/class/kgsl/kgsl-3d0
        do
    tweak 4 $kgsl_tweak/max_pwrlevel
    tweak 1 $kgsl_tweak/throttling
    tweak 4 $kgsl_tweak/thermal_pwrlevel 
    # tweak 1 $kgsl_tweak/force_clk_on (Disable Duplicate)
    tweak 1 $kgsl_tweak/force_bus_on 
    tweak 1 $kgsl_tweak/force_rail_on 
    tweak 0 $kgsl_tweak/force_no_nap 
    done
fi

# Mediatek

if [ -d "/sys/kernel/debug/fpsgo/common" ]; then
    tweak "0 0 0" /sys/kernel/debug/fpsgo/common/gpu_block_boost
fi

# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 1 "$queue/rq_affinity"

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 1
settings put secure low_priority 0

# From MTKVest

cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true

# From Corin 
cmd looper_stats enable

# Power Save Mode Off
settings put global low_power 0
}