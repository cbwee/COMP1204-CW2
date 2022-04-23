#!/bin/bash

# Check if this computer is a Raspberry Pi
is_raspi=false
# Check if this computer is a Raspberry Pi (running GNU/Linux, not Android)
if [[ $(uname -r) == *"v7l+"* ]] && [[ $(uname -m) == "armv7l" ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
	is_raspi=true
fi

echo "Is Raspberry Pi: $is_raspi"

login_MySQL="mysql -u root"
# If the script is not running on Raspberry Pi
if [ $is_raspi = false ] ; then
	login_MySQL="/opt/lampp/bin/${login_MySQL}"
fi
echo "Login MySQL: $login_MySQL"

$login_MySQL<<EOF
	CREATE DATABASE IF NOT EXISTS weatherJB;
	USE weatherJB;
EOF

if [ $is_raspi = true ] ; then
	CPU_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
	CPU_temp_c=$(echo "scale=2;$CPU_temp_raw / 1000" | bc)
	echo "CPU Temperature: $CPU_temp_c °C"
fi

$login_MySQL -e "SHOW DATABASES;"
