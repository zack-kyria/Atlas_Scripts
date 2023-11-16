#!/bin/bash

# Read device IPs from DeviceList.txt into an array
mapfile -t devices < "./DeviceList.txt"

# Loop over devices and execute command
for device in "${devices[@]}"; do
  adb connect $device:5555
  adb -s $device:5555 shell su -c "am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService"
  adb disconnect
done
