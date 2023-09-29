#!/bin/bash

# Read device IPs from DeviceList.txt into an array
mapfile -t devices < "./DeviceList.txt"

# Define your module path
module_path="eMagisk-Ethernet-Check-MOD.zip"

# Loop over devices and install the module
for device in "${devices[@]}"; do
  adb connect $device:5555
  adb -s $device:5555 push $module_path /data/local/tmp/
  adb -s $device:5555 shell su -c "magisk --install-module /data/local/tmp/$(basename $module_path)"
  adb -s $device:5555 reboot
  adb disconnect
done
