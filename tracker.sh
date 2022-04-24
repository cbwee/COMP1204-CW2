#!/bin/bash

user_agent="Mozilla/5.0 (Linux) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.84 Safari/537.36 SotonCOMP1204/2.0"
address="https://www.accuweather.com/en/my/johor-bahru/228029/weather-forecast/228029"
page=$(curl -A "$user_agent" $address)
echo

is_raspi=false
# Check if this computer is a 64-bit/32-bit Raspberry Pi (running GNU/Linux, not Android)
if [[ $(uname -r) == @(*"v8+"|*"v7l+") ]] && [[ $(uname -m) == @("aarch64"|"armv7l") ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
	is_raspi=true
fi
echo "Is Raspberry Pi: $is_raspi"

# Bash functions for MySQL
reset_auto_increment_if_empty() {
	echo -e "Database: $1\nTable: $2"
	rai_count=$(($login_MySQL -e "USE $1; select COUNT(*) from $2;"))
	if (( "$rai_count" == 0 )); then
		echo "Table $2 is empty"
	else
		echo "Table $2 is not empty"
	fi
	echo "$rai_count"
}

# <<<<< Start finding data >>>>>

# Find the temperature values
temperatures=$(echo "$page"| grep '<div class="temp">' | cut -d "&" -f 1 | cut -d ">" -f 2)
echo -e "\nTemperatures:\n${temperatures}\n"

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
	# Use echo -e to display \n as a line break
	echo -e "\nCPU Temperature: $CPU_temp_c °C\n"
	
	$login_MySQL -e "CREATE DATABASE IF NOT EXISTS cputemp;\
	USE cputemp;\
	CREATE TABLE IF NOT EXISTS cpuTemp(\
   	ID int UNIQUE NOT NULL AUTO_INCREMENT,\
    	Temp_C float NOT NULL,\
    	DateTime DateTime NOT NULL,\
    	PRIMARY KEY (ID)\
	);\
	
	#IF NOT EXISTS(SELECT * FROM cpuTemp) THEN\
      	#SELECT 'TEST';\	
	"
	$login_MySQL -e "USE cputemp; SHOW COLUMNS FROM cpuTemp; SELECT * FROM cpuTemp;"
	
	#Reset auto increment if table is empty
	reset_auto_increment_if_empty "cputemp" "cpuTemp"
	: '
	$login_MySQL -e "\
	USE cputemp;\
	INSERT INTO cpuTemp(Temp_C, DateTime) VALUES($CPU_temp_c, NOW());"
	'
fi

$login_MySQL -e "SHOW DATABASES;"
