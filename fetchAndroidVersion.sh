#!/bin/bash

# Read device IPs from DeviceList.txt into an array
mapfile -t devices < "./DeviceList.txt"

# Loop through the device IPs
for ip in "${devices[@]}"; do
    
    # Attempt to connect to the device
    adb connect $ip:5555 > /dev/null 2>&1
    
    # Check if the connection was successful
    if adb -s $ip:5555 shell getprop 2>/dev/null | grep -q 'ro.build.version.release'; then
        # Retrieve and print the Android version
        android_version=$(adb -s $i shell "cat /data/local/tmp/atlas_config.json" | awk -F\" '{print $12}')
        echo "Device at $ip is running Android version $android_version"
    else
        echo "No device found at $ip or unable to retrieve Android version."
    fi
    
    # Disconnect from the device
    adb disconnect $ip:5555 > /dev/null 2>&1
done
