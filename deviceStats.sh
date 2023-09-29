#!/usr/bin/env bash

discord_webhook="your_discord_webhook"
adb kill-server

version=$1
mapfile -t devices < "./DeviceList.txt"


totalPokemonCount=0
totalPtoJsonCount=0
totalGmoEmptyCount=0
deviceCount=0


for i in "${devices[@]}"; do

    adb connect $i:5555
    type=$(adb -s $i:5555 shell uname -m)
    echo "Connecting to $i"
    atlasDeviceName=$(adb -s $i shell "cat /data/local/tmp/atlas_config.json" | awk -F\" '{print $12}')
    echo "Checking Device Name:$atlasDeviceName"
    deviceTempRaw=$(adb -s $i shell "cat  /sys/class/thermal/thermal_zone0/temp")
    deviceTemp=$(awk -v raw=$deviceTempRaw 'BEGIN { printf "%.2f", raw/1000 }')
    echo "Checking Device Temp:$deviceTemp°C"
    # The rest of your original script remains unchanged
    pogoVer=$(adb -s $i shell dumpsys package com.nianticlabs.pokemongo | grep versionName |cut -d "=" -f 2)
    echo "Checking PoGo Version:$pogoVer"
    atvupti=$(adb -s $i shell uptime |cut -d "," -f 1 |awk '{ $1=$2="";$0=$0;} NF=NF')
    echo "Checking Uptime:$atvupti"
    atlasVer=$(adb -s $i shell dumpsys package com.pokemod.atlas | grep versionName |cut -d "=" -f 2)
    echo "Checking Atlas Version:$atlasVer"
    magiskVer=$(adb -s $i shell dumpsys package com.topjohnwu.magisk | grep versionName |cut -d "=" -f 2)
    echo "Checking Magisk Version:$magiskVer"
    vendingVer=$(adb -s $i shell dumpsys package com.android.vending | grep versionName |head -n 1|cut -d "=" -f 2)
    echo "Checking Playstore Version:$vendingVer"
    ptojson=$(adb -s $i shell "grep \"p.toJSON\" /data/local/tmp/*.log |wc -l")
    echo "Checking for Pto.json Error:$ptojson"
    gmoEmpty=$(adb -s $i shell "grep -o 'Another empty GMO?' /data/local/tmp/atlas.log | wc -l")
    echo "Checking for 'Another empty GMO?' Errors: $gmoEmpty"
    noPokemonCount=$(adb -s $i shell "grep -o 'No pokemon found' /data/local/tmp/atlas.log | wc -l")
    echo "Checking for 'No pokemon found' Phrases: $noPokemonCount"

    [[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"__**$atlasDeviceName**__: \n Device temp: ${deviceTemp}°C \n Pogo Version: $pogoVer \n ATV Uptime: $atvupti \n Atlas Version: $atlasVer \n Magisk Version: $magiskVer \n Playstore Version: $vendingVer \n GMO Errors: $gmoEmpty \n No Pokemon Found Count: $noPokemonCount \"}" $discord_webhook &>/dev/null

    totalPokemonCount=$((totalPokemonCount + noPokemonCount))
    totalPtoJsonCount=$((totalPtoJsonCount + ptojson))
    totalGmoEmptyCount=$((totalGmoEmptyCount + gmoEmpty))
    deviceCount=$((deviceCount + 1))

done

if [ $deviceCount -gt 0 ]; then
    averagePokemonCount=$(awk -v total=$totalPokemonCount -v count=$deviceCount 'BEGIN { printf "%.2f", total/count }')
    averagePtoJsonCount=$(awk -v total=$totalPtoJsonCount -v count=$deviceCount 'BEGIN { printf "%.2f", total/count }')
    averageGmoEmptyCount=$(awk -v total=$totalGmoEmptyCount -v count=$deviceCount 'BEGIN { printf "%.2f", total/count }')

    echo "Average 'No pokemon found' Count Across All Devices: $averagePokemonCount"
    echo "Average 'Pto.json' Count Across All Devices: $averagePtoJsonCount"
    echo "Average 'Another empty GMO?' Count Across All Devices: $averageGmoEmptyCount"

    [[ ! -z $discord_webhook ]] && curl -S -k -L --fail --show-error -F "payload_json={\"content\": \"Average 'No pokemon found' Count: $averagePokemonCount\nAverage 'Pto.json' Count: $averagePtoJsonCount\nAverage 'Another empty GMO?' Count: $averageGmoEmptyCount\"}" $discord_webhook &>/dev/null
fi
