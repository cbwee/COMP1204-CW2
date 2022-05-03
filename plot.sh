#!/bin/bash

echo

# Assign variables
db_name="weather_jb"
tableArr=("current" "tomorrow" )
plotName=("1._Temperature_and_RealFeel.png" "2._Average_Temperature" "3._CPU_Temperature.png")

png_size="set term png size 2160,1080 font ,20"
xytics="set xtics font ',12'; set ytics font ',14'; set xtics 60*60*12; set ytics 1"
xtime="set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'; set format x \"%Y-%m-%d\n%H:%M\""
x_dt="set xlabel 'Date and Time'"
y_tc="set ylabel 'Temperature (°C)'"
y_range="set yrange[25:41]"

directory=$HOME
temp="/dev/shm/"

cpu_fn="${temp}cpu_data_plot.txt"

ct_fn="${temp}current_temperature_data_plot.txt"
crf_fn="${temp}current_realfeel_data_plot.txt"

avgch_fn="${temp}average_current_high_plot.txt"
avgcl_fn="${temp}average_current_low_plot.txt"
avgcavg_fn="${temp}average_current_average_plot.txt"

avgth_fn="${temp}average_tomorrow_high_plot.txt"
avgtl_fn="${temp}average_tomorrow_low_plot.txt"
avgtavg_fn="${temp}average_tomorrow_average_plot.txt"

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
current_temp=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, Temp FROM ${tableArr[0]};")

current_RF=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, RealFeel FROM ${tableArr[0]};")
	
echo "# $current_temp" > $ct_fn
echo "# $current_RF" > $crf_fn
	
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
	plot "$ct_fn" using 1:3 with lines title "Temperature" ls 1, \
	"$crf_fn" using 1:3 with lines title "RealFeel" ls 2
EOF
	
	
# Plot 2
cavg="${tableArr[0]}_avg"
tavg="${tableArr[1]}_avg"

avgch=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, High FROM $cavg;")

avgcl=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, Low FROM $cavg;")
	
avgcavg=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, Average FROM $cavg;")
	
echo "# $avgch" > $avgch_fn
echo "# $avgcl" > $avgcl_fn
echo "# $avgcavg" > $avgcavg_fn
echo "# $avgth" > $avgth_fn
echo "# $avgtl" > $avgtl_fn
echo "# $avgtavg" > $avgtavg_fn
	
	
gnuplot <<- EOF
	set title "Average temperature"
	$x_dt
	$y_tc
	$xtime
	$xytics	
	$y_range
	$png_size
	set output "${directory}/${plotName[1]}"
	set style line 1 lc rgb "#93c701"
	set style line 2 lc rgb "#f05514"	
	plot "$ct_fn" using 1:3 with lines title "Temperature" ls 1, \
	"$crf_fn" using 1:3 with lines title "RealFeel" ls 2
EOF
	
: '
rm $ct_fn
rm $srf_fn
rm $avgch_fn
rm $avgcl_fn
rm $avgcavg_fn
rm $avgth_fn
rm $avgtl_fn
rm $avgtavg_fn
'


# Plot 3, only for Raspberry Pi
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
	set output "${directory}/${plotName[2]}"
	set style line 1 lc rgb "#cc2455"
	plot "$cpu_fn" using 1:3 with lines notitle ls 1
EOF
	rm $cpu_fn
fi
