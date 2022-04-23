#!/bin/bash

CPU_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
CPU_temp_c =$(echo "scale=2;$CPU_temp_raw / 1000" | bc)
echo "Temperature: $CPU_temp_c °C"

# Use mysql -u root if the environment is set, or the script is running on Raspberry Pi
#/opt/lampp/bin/mysql -u root
mysql -u root<<EOF
	CREATE DATABASE IF NOT EXISTS weatherJB;
	SHOW DATABASES;
	USE weatherJB;
EOF
