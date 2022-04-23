#!/bin/bash

user_agent="Mozilla/5.0 (Linux) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.84 Safari/537.36 SotonCOMP1204/2.0"
address="https://www.accuweather.com/en/my/johor-bahru/228029/weather-forecast/228029"
page=$"(curl -A "$user_agent" $address)"
echo

temperatures=$(echo $page | grep '<div class="temp">' | cut -d "&" -f 1 | cut -d ">" -f 2)
echo $temeratures

is_raspi=false
# Check if this computer is a 64-bit/32-bit Raspberry Pi (running GNU/Linux, not Android)
if [[ $(uname -r) == @(*"v8+"*|*"v7l+"*) ]] && [[ $(uname -m) == @("aarch64"|"armv7l") ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
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
	CREATE DATABASE IF NOT EXISTS weather_jb;
	USE weather_jb;
EOF

if [ $is_raspi = true ] ; then
	CPU_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
	CPU_temp_c=$(echo "scale=2;$CPU_temp_raw / 1000" | bc)
	echo "CPU Temperature: $CPU_temp_c °C"
	
	$login_MySQL -e "CREATE DATABASE IF NOT EXISTS cputemp;\
	USE cputemp;\
	CREATE TABLE IF NOT EXISTS cpuTemp(\
   	ID int UNIQUE NOT NULL AUTO_INCREMENT,\
    	Temperature int NOT NULL,\
    	DateTime DateTime NOT NULL,\
    	PRIMARY KEY (ID)\
	);\
	
	#IF NOT EXISTS(SELECT * FROM cpuTemp) THEN\
      	#SELECT 'TEST';\	
	"
	#// plan to add reset auto increment if table is empty
fi

$login_MySQL -e "SHOW DATABASES;"
