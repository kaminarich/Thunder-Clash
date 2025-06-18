#!/system/bin/sh

RAM_TOTAL_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
RAM_FREE_KB=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
RAM_TOTAL_GB=$(( (RAM_TOTAL_KB + 1048576 - 1) / 1048576 ))
RAM_FREE_GB=$(( (RAM_FREE_KB + 1048576 - 1) / 1048576 ))

get_cpu_codename() {
  local codename=$(getprop ro.mediatek.platform)
  [ -z "$codename" ] && codename=$(getprop ro.board.platform)
  [ -z "$codename" ] && codename=$(grep -m1 'Hardware' /proc/cpuinfo | cut -d ':' -f2 | sed 's/^[ \t]*//')
  echo "${codename:-unknown}"
}
ui_print "=========================================="
ui_print " _____ _                     _           "
ui_print "|_   _| |                   | |          "
ui_print "  | | | |__  _   _ _ __   __| | ___ _ __ "
ui_print "  | | | '_ \\| | | | '_ \\ / _\` |/ _ \\ '__|"
ui_print "  | | | | | | |_| | | | | (_| |  __/ |   "
ui_print "  \\_/ |_| |_|\\__,_|_| |_|\\__,_|\\___|_|   "
ui_print "                                         "
ui_print "                                         "
ui_print " _____ _           _                     "
ui_print "/  __ \\ |         | |                    "
ui_print "| /  \\/ | __ _ ___| |__                  "
ui_print "| |   | |/ _\` / __| '_ \\                 "
ui_print "| \\__/\\ | (_| \\__ \\ | | |                "
ui_print " \\____/_|\\__,_|___/_| |_|                "
ui_print "                                         "
ui_print "                                         "
# Header
ui_print "=========================================="
ui_print " "
ui_print "DEVICE       : $(getprop ro.build.product)"
ui_print "MODEL        : $(getprop ro.product.model)"
ui_print "MANUFACTURER : $(getprop ro.product.system.manufacturer)"
ui_print "BOARD        : $(getprop ro.product.board)"
ui_print "CODENAME     : $(get_cpu_codename)"
ui_print "ANDROID VER  : $(getprop ro.build.version.release)"
ui_print "KERNEL       : $(uname -r)"
ui_print "🧠 RAM       : ${RAM_TOTAL_GB} GB total / ${RAM_FREE_GB} GB free"
ui_print " "

# Dirty splash
sleep 1.2
case "$((RANDOM % 12 + 1))" in
  1)  ui_print "- CPU moaning, GPU throbbing—ThunderClash is in. 💦💻" ;;
  2)  ui_print "- Say goodbye to lags. ThunderClash fucks bottlenecks raw. 💀💪" ;;
  3)  ui_print "- Boot faster. Stroke frames harder. Cum at max FPS. 😈🎮" ;;
  4)  ui_print "- ThunderClash: because vanilla governors finish too early. 🍆🔥" ;;
  5)  ui_print "- This isn't a tweak. It's a gangbang for your scheduler. 💦⚙️" ;;
  6)  ui_print "- I/O? Tuned. CPU? Jacked. RAM? Dripping. Let's go. 💻💦" ;;
  7)  ui_print "- RAM stays tight. Performance stays hard. You're welcome. 😏📈" ;;
  8)  ui_print "- Stop choking frames. ThunderClash handles it deep. 🔧😈" ;;
  9)  ui_print "- She asked for smooth. ThunderClash gave her 120Hz multiple times. 🔥📲" ;;
  10) ui_print "- It's not overclocked… it's overstimulated. 🍌💻" ;;
  11) ui_print "- Lag? I don’t know her. ThunderClash made her scream and leave. 💀💦" ;;
  12) ui_print "- Dirty with sysfs. Rough with kernel. ThunderClash likes it raw. 🥵🖥️" ;;
esac

# Footer
ui_print " "
ui_print "=========================================="
ui_print "✅ ThunderClash injected – now ride that performance high, baby"
ui_print "=========================================="