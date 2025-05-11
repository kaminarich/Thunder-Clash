#!/bin/bash

# Menampilkan pesan konversi dimulai
echo "Proses konversi gamelist dimulai..."

# Membaca file gamelist.txt
echo "Membaca file: /data/adb/modules/ThunderClash/gamelist.txt"
cat /data/adb/modules/ThunderClash/gamelist.txt

# Lakukan konversi: ganti | dengan baris baru
sed 's/|/\n/g' /data/adb/modules/ThunderClash/gamelist.txt > /data/adb/modules/ThunderClash/gamelist_conv.txt

# Menampilkan hasil konversi
echo "File setelah konversi disimpan di: /data/adb/modules/ThunderClash/gamelist_conv.txt"
cat /data/adb/modules/ThunderClash/gamelist_conv.txt

# Menampilkan pesan konversi selesai
echo "Proses konversi selesai."