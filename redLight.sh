#!/bin/bash

# Define the command to be executed
COMMAND="su -c 'echo 1 > /sys/class/leds/power-red/brightness'"

# Read device IPs from DeviceList.txt into an array
mapfile -t devices < "./DeviceList.txt"

# Loop through the device IPs and execute the command
for IP_ADDRESS in "${devices[@]}"; do
  echo "Executing command on $IP_ADDRESS..."
  adb connect $IP_ADDRESS
  adb -s $IP_ADDRESS shell $COMMAND
  adb disconnect $IP_ADDRESS
done

echo "Command execution completed."
