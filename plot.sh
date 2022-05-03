#!/bin/bash

echo

# Assign variables
db_name="weather_jb"
tableArr=("current" "tomorrow" )
plotName=("1._Temperature_and_RealFeel.png" "2._Average_Temperature" "3._CPU_Temperature.png")

png_size="set term png size 2160,1080 font ,20"
xytics="set xtics font ',12'; set ytics font ',14'; set xtics 60*60*12; set ytics 1"
xtime="set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'; set format x \"%Y-%m-%d\n%H:%M\""
xdate="set xdata time; set timefmt '%m/%d/%Y'; set format x '%d %B %Y'; set xlabel 'Date'"
x_dt="set xlabel 'Date and Time'"
y_tc="set ylabel 'Temperature (°C)'"
y_range="set yrange[25:41]"

directory=$HOME
temp="/dev/shm/"
current_fn="${temp}${tableArr[0]}_temperature_data_plot.txt"
avgc_fn="${temp}average_${tableArr[0]}_plot.txt"
acgt_fn="${temp}average_${tableArr[1]}_plot.txt"

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

# Plot 1
current_data=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, Temp, RealFeel FROM ${tableArr[0]};")
	
echo "# $current_data" > $current_fn
	
gnuplot <<- EOF
	set title "Temperature and RealFeel"
	$x_dt
	$y_tc
	$xtime
	$xytics	
	$y_range
	$png_size
	set output "${directory}/${plotName[0]}"
	set style line 1 lc rgb "#93c701"
	set style line 2 lc rgb "#f05514"	
	plot "$current_fn" using 1:3 with lines title "Temperature" ls 1, \
	"$current_fn" using 1:4 with lines title "RealFeel" ls 2
EOF
	
# Plot 2

cavg="${tableArr[0]}_avg"
tavg="${tableArr[0]}_avg"

avgc=$($login_MySQL -e "USE $db_name;\
	SELECT Date, High, Low, Average FROM $cavg;")
	
avgt=$($login_MySQL -e "USE $db_name;\
	SELECT Date, High, Low, Average FROM $tavg;")

echo "# $avgc" > $avgc_fn
echo "# $avgt" > $avgt_fn

	
gnuplot <<- EOF
	set title "Average temperature"
	$y_tc
	$xdate
	$xytics	
	$y_range
	$png_size
	set output "${directory}/${plotName[1]}"
	set style line 1 lc rgb "#93c701"
	set style line 2 lc rgb "#f05514"	
	plot "$avgc_fn" using 1:2 with lines title "High" ls 1, \
	"$avgc_fn" using 1:3 with lines title "Low" ls 2, \
	"$avgc_fn" using 1:4 with lines title "Average", \
	"$avgt_fn" using 1:2 with lines title "Tomorrow High", \
	"$avgt_fn" using 1:3 with lines title "Tomorrow Low", \
	"$avgt_fn" using 1:4 with lines title "Tomorrow Average"
	
EOF

: '

# Plot 3, only for Raspberry Pi
if [ $is_raspi = true ]; then

	cpu_fn="${temp}cpu_data_plot.txt"
	
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
	set output "${directory}/${plotName[2]}"
	set style line 1 lc rgb "#cc2455"
	plot "$cpu_fn" using 1:3 with lines notitle ls 1
EOF
	rm $cpu_fn
fi
'
