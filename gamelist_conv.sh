#!/system/bin/sh
MODDIR=${0%/*}
GAMEFILE="$MODDIR/gamelist.txt"
CONVFILE="$MODDIR/gamelist_conv.txt"

[ -f "$GAMEFILE" ] || touch "$GAMEFILE"
sed 's/|/\n/g' "$GAMEFILE" | grep -v '^$' > "$CONVFILE"