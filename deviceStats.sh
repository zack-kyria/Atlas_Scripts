#!/usr/bin/env bash

## Initial Script from user lokixx on discord ##
## Further Changes applied by user clawofdead on discord ##
## My version follows below ##
# Works perfectly on H96Max RK3318/3328 (blue board)


# Function to determine the color based on the device temperature
# Attention! Temp values are in millidegrees Celsius (m°C). Which means 70000 is 70°C.
# Some devices use (m°C) and others just use Celsius. So you need to first check your own temperature setup
get_embed_color() {
    local temp_raw=$1
    if [[ ! -z "$temp_raw" ]]; then
        if [[ $temp_raw -gt 70000 ]]; then
            echo 16711680  # Red
        elif [[ $temp_raw -gt 60000 ]]; then
            echo 16776960  # Yellow
        else
            echo 65280     # Green
        fi
    else
        echo "No temperature data"
    fi
}

# ENTER YOU WEBHOOK URL FOR YOUR STATS CHANNEL
discord_webhook="your_discord_webhook"
adb kill-server

version=$1

# File name must be `DeviceList.txt` or you need to change this line
mapfile -t devices < "./DeviceList.txt"

totalPokemonCount=0
totalPtoJsonCount=0
totalGmoEmptyCount=0
deviceCount=0

# Device Data Retrieval
for i in "${devices[@]}"; do
    adb connect $i:5555
    type=$(adb -s $i:5555 shell uname -m)
    echo "Connecting to $i"
    # Device Name
    atlasDeviceName=$(adb -s $i shell "cat /data/local/tmp/atlas_config.json" | awk -F\" '{print $12}')
    echo "Checking Device Name:$atlasDeviceName"
    # Device Temperature
    deviceTempRaw=$(adb -s $i shell "cat  /sys/class/thermal/thermal_zone0/temp")
    deviceTemp=$(awk -v raw=$deviceTempRaw 'BEGIN { printf "%.2f", raw/1000 }')
    echo "Checking Device Temp:$deviceTemp°C"
    # Device PoGo Version
    pogoVer=$(adb -s $i shell dumpsys package com.nianticlabs.pokemongo | grep versionName |cut -d "=" -f 2)
    echo "Checking PoGo Version:$pogoVer"
    # Device Uptime
    atvupti=$(adb -s $i shell uptime |cut -d "," -f 1 |awk '{ $1=$2="";$0=$0;} NF=NF')
    echo "Checking Uptime:$atvupti"
    # Device Atlas Version
    atlasVer=$(adb -s $i shell dumpsys package com.pokemod.atlas | grep versionName |cut -d "=" -f 2)
    echo "Checking Atlas Version:$atlasVer"
    # Device Magisk Version
    magiskVer=$(adb -s $i shell dumpsys package com.topjohnwu.magisk | grep versionName |cut -d "=" -f 2)
    echo "Checking Magisk Version:$magiskVer"
    # Device Play Store Version
    vendingVer=$(adb -s $i shell dumpsys package com.android.vending | grep versionName |head -n 1|cut -d "=" -f 2)
    echo "Checking Playstore Version:$vendingVer"
    # Device P.toJSON error count
    ptojson=$(adb -s $i shell "grep \"p.toJSON\" /data/local/tmp/*.log |wc -l")
    echo "Checking for Pto.json Error:$ptojson"
    # Device Empty GMO errors
    gmoEmpty=$(adb -s $i shell "grep -o 'Another empty GMO?' /data/local/tmp/atlas.log | wc -l")
    echo "Checking for 'Another empty GMO?' Errors: $gmoEmpty"
    # Device `No Pokemon Found` Error Count
    noPokemonCount=$(adb -s $i shell "grep -o 'No pokemon found' /data/local/tmp/atlas.log | wc -l")
    echo "Checking for 'No pokemon found' Phrases: $noPokemonCount"
    color=$(get_embed_color $deviceTempRaw)
    
# Device Data Output
    device_data=$(cat <<EOF
{
  "title": "📱 **Device Info: $atlasDeviceName**",
  "color": $color,
  "fields": [
    {"name": "**🌡 Device Temp**", "value": "*$deviceTemp°C*", "inline": true},
    {"name": "**🔢 Pogo Version**", "value": "$pogoVer", "inline": true},
    {"name": "**⏰ ATV Uptime**", "value": "$atvupti", "inline": true},
    {"name": "**🔧 Atlas Version**", "value": "$atlasVer", "inline": true},
    {"name": "**🛠 Magisk Version**", "value": "$magiskVer", "inline": true},
    {"name": "**🛒 Playstore Version**", "value": "$vendingVer", "inline": true},
    {"name": "**⚠ GMO Errors**", "value": "$gmoEmpty", "inline": true},
    {"name": "**🔍 No Pokemon Found**", "value": "$noPokemonCount", "inline": true},
    {"name": "**🚨 Pto.json Errors**", "value": "$ptojson", "inline": true}
  ]
}
EOF
)



    curl -S -k -L --fail --show-error -X POST -H "Content-Type: application/json" --data "{\"embeds\": [$device_data]}" $discord_webhook

    totalPokemonCount=$((totalPokemonCount + noPokemonCount))
    totalPtoJsonCount=$((totalPtoJsonCount + ptojson))
    totalGmoEmptyCount=$((totalGmoEmptyCount + gmoEmpty))
    deviceCount=$((deviceCount + 1))
done

# TOTAL AVERAGE DATA
if [ $deviceCount -gt 0 ]; then
    averagePokemonCount=$(awk -v total=$totalPokemonCount -v count=$deviceCount 'BEGIN { printf "%.2f", total/count }')
    averagePtoJsonCount=$(awk -v total=$totalPtoJsonCount -v count=$deviceCount 'BEGIN { printf "%.2f", total/count }')
    averageGmoEmptyCount=$(awk -v total=$totalGmoEmptyCount -v count=$deviceCount 'BEGIN { printf "%.2f", total/count }')

# TOTAL AVERAGE OUTPUT
    average_data=$(cat <<EOF
{
  "title": "📊 **Average Statistics**",
  "description": "Here are the average statistics gathered from all devices.",
  "color": 3447003,
  "fields": [
    {"name": "🔎 Average 'No pokemon found'", "value": "${averagePokemonCount}", "inline": true},
    {"name": "⚠️ Average 'Pto.json' Count", "value": "${averagePtoJsonCount}", "inline": true},
    {"name": "❗ Average 'Another empty GMO?'", "value": "${averageGmoEmptyCount}", "inline": true}
  ],
  "footer": {
    "text": "Statistics generated on $(date '+%Y-%m-%d %H:%M:%S %Z %:z')"
  }
}
EOF
)

# For debugging purposes, print the generated JSON on shell
echo "Generated JSON payload: $average_data"

# Send the POST request
curl -S -k -L --fail --show-error -X POST -H "Content-Type: application/json" --data "{\"embeds\": [$average_data]}" $discord_webhook

fi
