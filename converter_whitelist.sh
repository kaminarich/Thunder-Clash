#!/system/bin/sh
MODDIR=${0%/*}
WHITEFILE="$MODDIR/whitelist_apps.txt"
CONVFILE="$MODDIR/whitelist_conv.txt"

[ -f "$WHITEFILE" ] || touch "$WHITEFILE"
sed 's/|/\n/g' "$WHITEFILE" | grep -v '^$' > "$CONVFILE"