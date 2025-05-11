#!/bin/bash

# Menampilkan pesan konversi dimulai
echo "Proses konversi whitelist dimulai..."

# Membaca file whitelist_apps.txt
echo "Membaca file: /data/adb/modules/ThunderClash/whitelist_apps.txt"
cat /data/adb/modules/ThunderClash/whitelist_apps.txt

# Lakukan konversi: ganti baris kosong atau komentar dengan pengganti yang sesuai
sed '/^#/d' /data/adb/modules/ThunderClash/whitelist_apps.txt > /data/adb/modules/ThunderClash/whitelist_conv.txt

# Menampilkan hasil konversi
echo "File setelah konversi disimpan di: /data/adb/modules/ThunderClash/whitelist_conv.txt"
cat /data/adb/modules/ThunderClash/whitelist_conv.txt

# Menampilkan pesan konversi selesai
echo "Proses konversi selesai."