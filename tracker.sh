#!/bin/bash

echo
# Command line flag
append_data=false
if [ "$1" == "-a" ]; then
  append_data=true;
fi
echo "Append Data: $append_data"
if [ $append_data == false ]; then
	echo -e "(Use the -a flag if you want to append to the file)"
fi

user_agent="Mozilla/5.0 (Linux) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.84 Safari/537.36 SotonCOMP1204/2.0"
address="https://www.accuweather.com/en/my/johor-bahru/228029/weather-forecast/228029"
page=$(curl --silent -A "$user_agent" $address)
db_name="weather_jb"
echo

is_raspi=false
# Check if this computer is a 64-bit/32-bit Raspberry Pi (running GNU/Linux, not Android)
if [[ $(uname -r) == @(*"v8+"|*"v7l+") ]] && [[ $(uname -m) == @("aarch64"|"armv7l") ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
	is_raspi=true
fi
echo "Is Raspberry Pi: $is_raspi"

# Bash functions for MySQL
reset_auto_increment_if_empty() {
	echo
	# echo -e "Database: $1\nTable: $2"
	rai_count=$($login_MySQL -e "USE $1; select COUNT(*) from $2;" | tail -n 1)
	if [ "$rai_count" -eq "0" ]; then
		echo "Table $2 is empty"
		rai_initial_count=1
		$login_MySQL -e "USE $1; ALTER TABLE $2 AUTO_INCREMENT = $rai_initial_count;"
		echo "Auto increment value is reset to $rai_initial_count"
	else
		echo "Table $2 is not empty"
	fi
	echo
}

# <<<<< Start finding data >>>>>

page_title=$(echo "$page" | grep '<title>' | cut -d ">" -f 2 | cut -d "<" -f 1 |sed -s 's/\&amp;/\&/g' | sed -s "s/\&#x27;/\'/g")
echo -e "\n$page_title"
unit_temp=$(echo "$page" | grep '<span class="after-temp">' | cut -d ">" -f 3 | cut -d "<" -f 1 | head -n 1)

# Find the temperature values
temperatures=$(echo "$page" | grep '<div class="temp">' | cut -d "&" -f 1 | cut -d ">" -f 2)
# echo -e "\nTemperatures:\n${temperatures}\n"

# Find the date values
dates=$(echo "$page" | grep '<span class="sub-title">' | cut -d ">" -f 2 | cut -d "<" -f 1)
# echo -e "\nDates:\n${dates}\n"

# Find the RealFeel values
realFeels=$(echo "$page" | grep '<div class="real-feel">' | tail -n 3 | cut -d " " -f 3 | cut -d "&" -f 1)
# echo -e "\nRealFeels:\n${realFeels}\n"


# Current Data
echo
echo "=====Current====="
current_date=$(echo "$page" | grep '<p class="date">' | cut -d ">" -f 2 | cut -d "<" -f 1)
echo "Date: $current_date"

current_temp=$(echo "$temperatures" | head -n 1)
echo "Temperature: $current_temp $unit_temp"

current_realFeel=$(echo "$page" | grep '<div class="real-feel">' -A2 | sed -n 3p | cut -d "&" -f 1 | xargs)
echo "RealFeel: $current_realFeel $unit_temp"

current_time=$(echo "$page" | grep 'cur-con-weather-card__subtitle' -A1 | cut -d ">" -f 2 | xargs)
echo "Time: $current_time"

day_of_week=$(echo "$page" | grep '<p class="day-of-week">' | cut -d ">" -f 2 | cut -d "<" -f 1)
echo "Day of week: $day_of_week"

current_realFeelShade=$(echo "$page" | grep -A1 '<span class="label">RealFeel Shade&#x2122;</span>' | tail -n 1 | cut -d ">" -f 2 | cut -d "&" -f 1)
echo "RealFeel Shade: $current_realFeelShade $unit_temp"

current_aqi=$(echo "$page" | grep '<div class="aq-number">' -A1 | tail -n 1 | xargs)
current_air_quality=$( echo "$page" | grep '<p class="category-text">' | cut -d ">" -f 2 | cut -d "<" -f 1)
echo "Air Quality: $current_aqi, $current_air_quality"

# Today Data
echo
echo "=====Today====="
today_date=$(echo "$dates" | head -n 1)
echo "Date: $today_date"

today_temp=$(echo "$temperatures" | sed -n 2p)
echo "Temperature: $today_temp $unit_temp"

today_realFeel=$(echo "$realFeels" | sed -n 1p)
echo "RealFeel: $today_realFeel $unit_temp"

# Tonight Data
echo
echo "=====Tonight====="
tonight_date=$(echo "$dates" | sed -n 2p)
echo "Date: $tonight_date"

tonight_temp=$(echo "$temperatures" | sed -n 3p)
echo "Temperature: $tonight_temp $unit_temp"

tonight_realFeel=$(echo "$realFeels" | sed -n 2p)
echo "RealFeel: $tonight_realFeel $unit_temp"

# Tomorrow Data
echo
echo "=====Tomorrow====="
tomorrow_date=$(echo "$dates" | tail -n 1)
echo "Date: $tomorrow_date"

tomorrow_temp=$(echo "$temperatures" | tail -n 1)
echo "Temperature: $tomorrow_temp $unit_temp"

tomorrow_realFeel=$(echo "$realFeels" | sed -n 3p)
echo "RealFeel: $tomorrow_realFeel $unit_temp"

login_MySQL="mysql -u root"
# If the script is not running on Raspberry Pi
if [ $is_raspi = false ] ; then
	login_MySQL="/opt/lampp/bin/${login_MySQL}"
fi
echo -e "\nLogin MySQL: $login_MySQL"

$login_MySQL<<EOF
	CREATE DATABASE IF NOT EXISTS $db_name;
	USE $db_name;
EOF

if [ $is_raspi = true ] ; then
	CPU_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
	CPU_temp_c=$(echo "scale=2;$CPU_temp_raw / 1000" | bc)
	# Use echo -e to display \n as a line break
	echo -e "\nCPU Temperature: $CPU_temp_c °C"
	
	$login_MySQL -e "CREATE DATABASE IF NOT EXISTS cputemp;\
	USE cputemp;\
	CREATE TABLE IF NOT EXISTS cpuTemp(\
   	ID int UNIQUE NOT NULL AUTO_INCREMENT,\
    	Temp_C float NOT NULL,\
    	DateTime DateTime NOT NULL,\
    	PRIMARY KEY (ID)\
	);\
	"
	#$login_MySQL -e "USE cputemp; SHOW COLUMNS FROM cpuTemp; SELECT * FROM cpuTemp;"
	
	#Reset auto increment if table is empty
	reset_auto_increment_if_empty "cputemp" "cpuTemp"
	
	if [ $append_data == true ]; then
		: '
		$login_MySQL -e "\
		USE cputemp;\
		INSERT INTO cpuTemp(Temp_C, DateTime) VALUES($CPU_temp_c, NOW());"
		echo "CPU Temperature inserted."
		'
	fi
fi

