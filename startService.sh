#!/bin/bash

# Read device IPs from DeviceList.txt into an array
mapfile -t devices < "./DeviceList.txt"

# Define your module path
module_path="eMagisk-Ethernet-Check-MOD.zip"

# Loop over devices and install the module
for device in "${devices[@]}"; do
  adb connect $device:5555
  adb -s $device:5555 shell su -c "am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService"
  adb disconnect
done
