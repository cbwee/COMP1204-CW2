#!/bin/bash

echo

# Assign variables
db_name="weather_jb"
tableArr=("current" "tomorrow" )

is_raspi=false
# Check if this computer is a 64-bit/32-bit Raspberry Pi (running GNU/Linux, not Android)
if [[ $(uname -r) == @(*"v8+"|*"v7l+") ]] && [[ $(uname -m) == @("aarch64"|"armv7l") ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
	is_raspi=true
fi
echo "Raspberry Pi: $is_raspi"

login_MySQL="mysql -u root"
# If the script is not running on Raspberry Pi
if [ $is_raspi = false ] ; then
	login_MySQL="/opt/lampp/bin/${login_MySQL}"
fi
echo -e "\nCommand for MySQL login: $login_MySQL\n"

if [ $is_raspi = true ]; then

	cpu_data=$($login_MySQL -e "USE cputemp;\
	SELECT DateTime, Temp_C FROM cpuTemp;
	")
	
	#echo "$cpu_data"
	cpu_file_name="temp_cpu_data.txt"
	echo "$cpu_data" > $cpu_file_name
	
gnuplot <<- EOF
	
	set title "CPU Temperature"
	set xlabel "Time"
	set ylabel "Temperature (°C)"
	set output "$HOME/CPU_Temperature.png"
	set timefmt '"%Y-%m-%d %H:%M:%S"'
	plot "$cpu_file_name"
EOF

fi
