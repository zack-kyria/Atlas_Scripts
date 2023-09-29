#!/usr/bin/env bash

# ADB server kill and restart
adb kill-server
adb start-server

# Initialize ADB in TCP/IP mode
adb tcpip 5555

# Read device list into array
mapfile -t devices < "./DeviceList.txt"

# Initialize device count
deviceCount=0

# Loop through each device to perform actions
for i in "${devices[@]}"; do
    # Connect to the device
    adb connect $i:5555

    # Get device name for better logging (Optional)
    deviceName=$(adb -s $i shell "cat /data/local/tmp/atlas_config.json" | awk -F\" '{print $12}')
    echo "Connecting to $i ($deviceName)"

    # Install the APK
    adb -s $i:5555 install $apk_file
    echo "APK installed on $i ($deviceName)"

    # Force-stop the apps
    adb -s $i:5555 shell "su -c 'am force-stop com.nianticlabs.pokemongo && am force-stop com.pokemod.atlas'"
    echo "Force-stopped apps on $i ($deviceName)"

    # Start the service
    adb -s $i:5555 shell "am startservice com.pokemod.atlas/com.pokemod.atlas.services.MappingService"
    echo "Started MappingService on $i ($deviceName)"

    # Increment device count
    deviceCount=$((deviceCount + 1))

    adb disconnect
done

# Final summary
echo "Installed APK and performed actions on $deviceCount devices."
