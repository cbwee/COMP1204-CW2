#!/bin/bash

echo
# Command line flags
plot_files=false;
append_data=false
display_data=false
num_display=5;

if [ "$1" == "-a" ]; then
	append_data=true
elif [ "$1" == "-d" ]; then
	display_data=true
elif [ "$1" == "-p" ]; then
	plot_files=true
else
  echo -e "(Use the -a flag if you want to append the data to MySQL database)\n(Use the -p flag if you want to generate plots)"
fi
echo "Append Data: $append_data"

# Assign variables
user_agent="Mozilla/5.0 (Linux) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.84 Safari/537.36 SotonCOMP1204/2.0"
address="https://www.accuweather.com/en/my/johor-bahru/228029/weather-forecast/228029"
db_name="weather_jb"

# An array of table names
tableArr=("current" "tomorrow" )

if ! page=$(curl --silent -A "$user_agent" $address) ; then
	echo -e "\ncurl failed"; exit 1;
fi
echo

is_raspi=false
# Check if this computer is a 64-bit/32-bit Raspberry Pi (running GNU/Linux, not Android)
if [[ $(uname -r) == @(*"v8+"|*"v7l+") ]] && [[ $(uname -m) == @("aarch64"|"armv7l") ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
	is_raspi=true
fi
echo "Raspberry Pi: $is_raspi"

# Bash functions for MySQL
reset_auto_increment_if_empty() {
	local rai_count=$($login_MySQL -e "USE $1; SELECT COUNT(*) from $2;" | tail -n 1)
	if [ "$rai_count" -eq "0" ]; then
		echo "Table $2 is empty"
		rai_initial_count=1
		$login_MySQL -e "USE $1; ALTER TABLE $2 AUTO_INCREMENT = $rai_initial_count;"
		echo "Auto increment value of $2 is reset to $rai_initial_count"
	else
		echo "Table $2 has $rai_count rows of data"
		if [ $display_data = true ]; then
			$login_MySQL -e "USE $1; (SELECT * FROM $2 ORDER BY ID DESC LIMIT $num_display) ORDER BY ID;"
		fi
	fi
	echo
}

display_last_insert() {
	# echo -e "Database: $1\nTable: $2\nColumn Name: $3"
	# Use a local variable
	local count=$($login_MySQL -e "USE $1; SELECT COUNT($3) FROM $2;" | tail -n 1)
	if [ $count -ne "0" ]; then
		local last=$($login_MySQL -e "USE $1; SELECT $3 FROM $2 ORDER BY ID DESC LIMIT 1;" | tail -n 1)
		echo "Last Data Insertion: $last"
		echo
	fi
}

# <<<<< Start finding data >>>>>

page_title=$(echo "$page" | grep -iE '<TITLE>' | cut -d ">" -f 2 | cut -d "<" -f 1 |sed -s 's/\&amp;/\&/g' | sed -s "s/\&#x27;/\'/g")

if [[ "$page_title" == "Access Denied" ]]; then
	echo  -e "\n$page_title"; exit 1;
fi

echo -e "\n\n($page_title)"
unit_temp=$(echo "$page" | grep 'class="after-temp"' | cut -d ">" -f 3 | cut -d "<" -f 1 | head -n 1)

# Find the temperature values
temperatures=$(echo "$page" | grep 'class="temp"' | cut -d "&" -f 1 | cut -d ">" -f 2)
# echo -e "\nTemperatures:\n${temperatures}\n"

# Find the date values
dates=$(echo "$page" | grep 'class="sub-title"' | cut -d ">" -f 2 | cut -d "<" -f 1)
# echo -e "\nDates:\n${dates}\n"

# Find the RealFeel values
realFeels=$(echo "$page" | grep 'class="real-feel"' | tail -n 3 | cut -d " " -f 3 | cut -d "&" -f 1)
# echo -e "\nRealFeels:\n${realFeels}\n"

# Find the phrase values
phrases=$(echo "$page" | grep 'class="phrase"' | cut -d ">" -f 2 | cut -d "<" -f 1)
# echo -e "\nPhrases:\n${phrases}\n"

# Current Data
echo
echo "===== Current ====="
current_date=$(echo "$page" | grep 'class="date"' | cut -d ">" -f 2 | cut -d "<" -f 1)
echo "Date: $current_date"

current_temp=$(echo "$temperatures" | head -n 1)
echo "Temperature: $current_temp $unit_temp"

current_realFeel=$(echo "$page" | grep 'class="real-feel"' -A2 | sed -n 3p | cut -d "&" -f 1 | xargs)
echo "RealFeel: $current_realFeel $unit_temp"

current_phrase=$(echo "$phrases" | sed -n 1p)
echo "Phrase: $current_phrase"

current_time=$(echo "$page" | grep 'cur-con-weather-card__subtitle' -A1 | cut -d ">" -f 2 | xargs)
echo "Time: $current_time"

# Removed day of week because it became "Today" during testing
# Removed realFeelShade because the data is not available at night

current_aqi=$(echo "$page" | grep 'class="aq-number"' -A1 | tail -n 1 | xargs)
current_air_quality=$(echo "$page" | grep 'class="category-text"' | cut -d ">" -f 2 | cut -d "<" -f 1)
echo "Air Quality: $current_aqi, $current_air_quality"

wind_and_gusts=$(echo "$page" | grep 'class="label">Wind'  -A1 | grep -v "label" | cut -d ">" -f 2 | cut -d "<" -f 1)

current_wind=$(echo "$wind_and_gusts" | head -n 1)
echo "Wind: $current_wind"

current_wind_gusts=$(echo "$wind_and_gusts" | tail -n 1)
echo "Wind Gusts: $current_wind_gusts"

# Removed Today(High) Data and Tonight(Low) Data, because at night Today(High) Data is not available

# Tomorrow Data
echo
echo "===== Tomorrow ====="
tomorrow_date=$(echo "$dates" | tail -n 1)
echo "Date: $tomorrow_date"

tomorrow_temp_high=$(echo "$temperatures" | tail -n 1)
echo "Temperature High: $tomorrow_temp_high $unit_temp"

tomorrow_temp_low=$(echo "$page" | grep 'class="after-temp">/' | cut -d " " -f 4 | cut -d "&" -f 1)
echo "Temperature Low: $tomorrow_temp_low $unit_temp"

tomorrow_realFeel=$(echo "$realFeels" | tail -n 1)
echo "RealFeel: $tomorrow_realFeel $unit_temp"

tomorrow_phrase=$(echo "$phrases" | tail -n 1)
echo "Phrase: $tomorrow_phrase"
echo

login_MySQL="mysql -u root"
# If the script is not running on Raspberry Pi
if [ $is_raspi = false ] ; then
	login_MySQL="/opt/lampp/bin/${login_MySQL}"
fi
echo -e "\nCommand for MySQL login: $login_MySQL\n"

# <<<<< Create Database and Tables >>>>>

# Try using EOF and create the database
$login_MySQL<<EOF
	CREATE DATABASE IF NOT EXISTS $db_name;
EOF

$login_MySQL -e "USE $db_name;\
	# Create tables
	# Current weather
	CREATE TABLE IF NOT EXISTS ${tableArr[0]}(\
   	ID int UNIQUE NOT NULL AUTO_INCREMENT,\
	Date CHAR(10) NOT NULL,\
    	Temp int NOT NULL,\
	RealFeel int NOT NULL,\
	Phrase CHAR(100) NOT NULL,\
	Time CHAR(50) NOT NULL,\
	AQI int NOT NULL,\
	AirQuality CHAR(50) NOT NULL,\
	Wind CHAR(50) NOT NULL,\
	WindGusts CHAR(50) NOT NULL,\
    	DateTime DateTime NOT NULL,\
    	PRIMARY KEY (ID)\
	);\
		
	# Tomorrow weather
	CREATE TABLE IF NOT EXISTS ${tableArr[1]}(\
   	ID int UNIQUE NOT NULL AUTO_INCREMENT,\
	Date CHAR(10) NOT NULL,\
    	Temp_high int NOT NULL,\
	Temp_low int NOT NULL,\
	RealFeel int NOT NULL,\
	Phrase CHAR(100) NOT NULL,\
    	DateTime DateTime NOT NULL,\
    	PRIMARY KEY (ID)\
	);\
	
	# Create Views
	# Current average
	CREATE VIEW IF NOT EXISTS ${tableArr[0]}_avg AS \
	SELECT CONCAT(Date, '/', YEAR(DateTime)) as Date, MAX(Temp) + 0.0000 as High, MIN(Temp) + 0.0000 as Low, AVG(Temp) as Average, AVG(RealFeel) as RealFeel \
	FROM ${tableArr[0]} GROUP BY Date;\
	
	# Tomorrow average
	CREATE VIEW IF NOT EXISTS ${tableArr[1]}_avg AS \
	SELECT CONCAT(Date, '/', YEAR(DateTime)) as Date, AVG(Temp_high) as High, AVG(Temp_low) as Low, AVG((Temp_high + Temp_Low) / 2) as Average, AVG(RealFeel) as RealFeel \
	FROM ${tableArr[1]} GROUP BY Date;\
	"
	
for table_name in ${tableArr[@]}; do
  reset_auto_increment_if_empty $db_name $table_name
done

if [ "$unit_temp" = "C" ]; then
	if [ $append_data == true ]; then
		echo "Start inserting data"		
		$login_MySQL -e "\
		USE $db_name;\
		
		INSERT INTO ${tableArr[0]}(Date, Temp, RealFeel, Phrase, Time, AQI, AirQuality, Wind, WindGusts, DateTime) \
		VALUES(\"$current_date\", $current_temp, $current_realFeel, \"$current_phrase\", \"$current_time\", $current_aqi, \
		\"$current_air_quality\", \"$current_wind\", \"$current_wind_gusts\", NOW());
		SELECT * FROM ${tableArr[0]} ORDER BY ID DESC LIMIT 1;\
		
		INSERT INTO ${tableArr[1]}(Date, Temp_high, Temp_low, RealFeel, Phrase, DateTime) \
		VALUES(\"$tomorrow_date\", $tomorrow_temp_high, $tomorrow_temp_low, $tomorrow_realFeel, \"$tomorrow_phrase\", NOW());
		SELECT * FROM ${tableArr[1]} ORDER BY ID DESC LIMIT 1;\
		"
		echo -e "Data inserted\n"	
	fi
elif ["$unit_temp" = "F" ]; then
	# It is possible to have the unit F if connecting from the US
	echo "This script does not support imperial units"
else
	echo "Error, unknown unit"
fi

if [ $is_raspi = true ]; then
	# Find the CPU temperature by reading the file
	CPU_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
	# CPU temperature in degree Celsius
	CPU_temp_c=$(echo "scale=2;$CPU_temp_raw / 1000" | bc)
	# Use echo -e to display \n as a line break
	echo -e "CPU Temperature: $CPU_temp_c °C\n"
	
	$login_MySQL -e "CREATE DATABASE IF NOT EXISTS cputemp;\
	USE cputemp;\
	CREATE TABLE IF NOT EXISTS cpuTemp(\
   	ID int UNIQUE NOT NULL AUTO_INCREMENT,\
    	Temp_C float NOT NULL,\
    	DateTime DateTime NOT NULL,\
    	PRIMARY KEY (ID)\
	);\
	"
	
	# Reset auto increment if the table is empty
	reset_auto_increment_if_empty "cputemp" "cpuTemp"
	
	if [ $append_data == true ]; then
		$login_MySQL -e "\
		USE cputemp;\
		INSERT INTO cpuTemp(Temp_C, DateTime) VALUES($CPU_temp_c, NOW());\
		SELECT * FROM cpuTemp ORDER BY ID DESC LIMIT 1;\
		"
		echo -e "CPU Temperature inserted\n"
	fi
fi

if [ "$append_data" = false ] && [ "$display_data" = false ]; then
	display_last_insert $db_name ${tableArr[0]} "DateTime"
fi

if [ "$plot_files" = true ]; then
	chmod u+x plot.sh
	bash ./plot.sh
fi
