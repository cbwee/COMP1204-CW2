#!/bin/bash

# Check if this computer is a Raspberry Pi
is_raspi=false
if [[ $(uname -r) == *"v7l+"* ]] && [[ $(uname -m) == "armv7l" ]]; then
	is_raspi=true
fi

echo "Is Raspberry Pi: $is_raspi"

: '
CPU_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
CPU_temp_c=$(echo "scale=2;$CPU_temp_raw / 1000" | bc)
echo "CPU Temperature: $CPU_temp_c °C"
'

# Use mysql -u root if the environment is set, or the script is running on Raspberry Pi
#/opt/lampp/bin/mysql -u root
mysql -u root<<EOF
	CREATE DATABASE IF NOT EXISTS weatherJB;
	USE weatherJB;
EOF

mysql -u root -e "SHOW DATABASES;"
