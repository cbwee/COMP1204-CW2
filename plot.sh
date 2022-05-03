#!/bin/bash

echo

# Assign variables
db_name="weather_jb"
tableArr=("current" "tomorrow" )

png_size="set term png size 2160,1080 font ,20"
xytics="set xtics font ',12'; set ytics font ',14'; set xtics 60*60*12; set ytics 1"
xtime="set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'; set format x \"%Y-%m-%d\n%H:%M\""
x_dt="set xlabel 'Date and Time'"
y_tc="set ylabel 'Temperature (°C)'"
y_range="set yrange[25:41]"

temp="/dev/shm/"
cpu_fn="${temp}temp_cpu_data.txt"
ct_fn="${temp}ct_data.txt"
crf_fn="${temp}crf_data.txt"

is_raspi=false
# Check if this computer is a 64-bit/32-bit Raspberry Pi
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

current_temp=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, Temp FROM ${tableArr[0]};")

current_RF=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, RealFeel FROM ${tableArr[0]};")
	
	echo "# $current_temp" > $ct_fn
	echo "# $current_RF" > $crf_fn
	
gnuplot <<- EOF
	set title "Temperature and RealFeel"
	set xlabel "Date and Time"
	set ylabel "Temperature (°C)"
	$xtime
	$xytics	
	$png_size
	set output "$HOME/1._Temperature_and_RealFeel.png"
	set style line 1 lc rgb "#93c701"
	set style line 2 lc rgb "#f05514"	
	plot "$ct_fn" using 1:3 with lines title "Temperature" ls 1, "$crf_fn" using 1:3 with lines title "RealFeel" ls 2
EOF
	#rm $ct_fn
	#rm $srf_fn



if [ $is_raspi = true ]; then

	cpu_data=$($login_MySQL -e "USE cputemp;\
	SELECT DateTime, Temp_C FROM cpuTemp;")
	
	echo "# $cpu_data" > $cpu_fn
	
gnuplot <<- EOF
	set title "CPU Temperature"
	$x_dt
	$y_tc
	$xtime
	$xytics	
	$png_size
	set output "$HOME/3._CPU_Temperature.png"
	set style line 1 lc rgb "#cc2455"
	plot "$cpu_fn" using 1:3 with lines notitle ls 1
EOF
	rm $cpu_fn
fi
