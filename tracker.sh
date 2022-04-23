#!/bin/bash

# Check if this computer is a Raspberry Pi
is_raspi=false
# If the kernel release contains
if [[ $(uname -r) == *"v7l+"* ]] && [[ $(uname -m) == "armv7l" ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
	is_raspi=true
fi

echo "Is Raspberry Pi: $is_raspi"

# Use mysql -u root if the script is running on Raspberry Pi
login_MySQL="mysql -u root"
if [ $is_raspi = false ] ; then
	login_MySQL="/opt/lampp/bin/${login_MySQL}"
fi

login_MySQL<<EOF
	CREATE DATABASE IF NOT EXISTS weatherJB;
	USE weatherJB;
EOF

if [ $is_raspi = true ] ; then
	CPU_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
	CPU_temp_c=$(echo "scale=2;$CPU_temp_raw / 1000" | bc)
	echo "CPU Temperature: $CPU_temp_c °C"
fi

mysql -u root -e "SHOW DATABASES;"
