#!/usr/bin/env bash

# ADB server kill and restart
adb kill-server
adb start-server

# Specify the APK file name
apk_file="PokemodAtlas-Public-v23071801.apk"

# Read device list into array
mapfile -t devices < "./DeviceList.txt"

# Initialize device count
deviceCount=0

# Loop through each device and install APK then reboot
for i in "${devices[@]}"; do
    # Connect to the device
    adb connect $i:5555

    # Get device name
    deviceName=$(adb -s $i shell "cat /data/local/tmp/atlas_config.json" | awk -F\" '{print $12}')
    echo "Connecting to $i ($deviceName)"

    # Install the APK
    adb -s $i:5555 install -r $apk_file
    echo "APK installed on $i ($deviceName)"

    # Reboot the device
    adb -s $i:5555 reboot
    echo "Rebooted $i ($deviceName)"

    # Increment device count
    deviceCount=$((deviceCount + 1))
done

# Final summary and Discord notification
echo "Installed APK and rebooted on $deviceCount devices."
