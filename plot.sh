#!/bin/bash
echo

# Assign variables
db_name="weather_jb"
tableArr=("current" "tomorrow" )
plotName=("1._Temperature_and_RealFeel.png" "2._Average_Temperature.png" "3._CPU_Temperature.png")

png_size="set term png size 2160,1080 font 'times new roman,20'"
xyfonts="set xtics font ',12'; set ytics font ',14'"
xtime="set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'; set format x \"%Y-%m-%d\n%H:%M\""
xdate="set xdata time; set timefmt '%m/%d/%Y'; set format x '%d %B %Y'; set xlabel 'Date'"
x_dt="set xlabel 'Date and Time'"
y_tc="set ylabel 'Temperature (°C)'"

directory=$HOME
# Store temporary files in RAM
temp="/dev/shm/"
# File names
current_fn="${temp}${tableArr[0]}_temperature_data_plot.txt"
avgc_fn="${temp}average_${tableArr[0]}_plot.txt"
avgt_fn="${temp}average_${tableArr[1]}_plot.txt"

# An array that stores the names of files generated
finished_plots=()

is_raspi=false
# Check if this computer is a 64-bit/32-bit Raspberry Pi
if [[ $(uname -r) == @(*"v8+"|*"v7l+") ]] && [[ $(uname -m) == @("aarch64"|"armv7l") ]] && [[ $(uname -o) == "GNU/Linux" ]]; then
	is_raspi=true
fi

login_MySQL="mysql -u root"
# If the script is not running on Raspberry Pi
if [ $is_raspi = false ] ; then
	login_MySQL="/opt/lampp/bin/${login_MySQL}"
fi

# Plot 1
current_data=$($login_MySQL -e "USE $db_name;\
	SELECT DateTime, Temp, RealFeel FROM ${tableArr[0]};")
	
# Store the data in a file	
echo "# $current_data" > $current_fn
	
gnuplot <<- EOF
	set title "Temperature and RealFeel"
	$x_dt
	$y_tc
	$xtime
	$xyfonts
	# tics for every degree
	set ytics 1
	set key font ',16'
	# tics for every 12 hours
	set xtics 60*60*12;
	# set range from 25 to 41 degrees
	set yrange[25:41]
	# range from 9 days ago until now
	set xrange [time(0) - 9*24*60*60:time(0)]
	$png_size
	set output "${directory}/${plotName[0]}"
	# set line colours
	set style line 1 lc rgb "#288adb"
	set style line 2 lc rgb "#f05514"	
	plot "$current_fn" using 1:3 with lines title "Temperature" ls 1, \
	"$current_fn" using 1:4 with lines title "RealFeel" ls 2
EOF
# Delete the file	
rm $current_fn
finished_plots+=("${plotName[0]}")
	
# Plot 2

# Names of views
cavg="${tableArr[0]}_avg"
tavg="${tableArr[1]}_avg"

avgc=$($login_MySQL -e "USE $db_name;\
	SELECT Date, High, Low, Average FROM $cavg;")
	
avgt=$($login_MySQL -e "USE $db_name;\
	SELECT Date, High, Low, Average FROM $tavg;")

# Save data to files
echo "# $avgc" > $avgc_fn
echo "# $avgt" > $avgt_fn
	
gnuplot <<- EOF
	set title "Average temperature"
	$y_tc
	$xdate
	$xyfonts
	set xtics font ',14'
	set xtics 60*60*24
	# hide minor tics
	set xtics scale 1,0
	# tics for every 0.5 degree
	set ytics 0.5
	set yrange[24:35]
	# range from 15 days ago until yesterday
	set xrange [time(0) - 15*24*60*60:time(0) - 24*60*60]
	set key font ',14'
	$png_size
	set output "${directory}/${plotName[1]}"
	# set line width and point type
	set style line 1 lc rgb "#ff1744" lw 2 pt 5
	set style line 2 lc rgb "#00b0ff" lw 2 pt 5
	set style line 3 lc rgb "#00e676" lw 2 pt 5
	set style line 4 lc rgb "#ff616f" pt 5
	set style line 5 lc rgb "#69e2ff" pt 5
	set style line 6 lc rgb "#66ffa6" pt 5
	plot \
	"$avgc_fn" using 1:2 with linespoints title "High" ls 1, \
	"$avgc_fn" using 1:3 with linespoints title "Low" ls 2, \
	"$avgc_fn" using 1:4 with linespoints title "Average" ls 3, \
	"$avgt_fn" using 1:2 with linespoints title "Tomorrow High" ls 4, \
	"$avgt_fn" using 1:3 with linespoints title "Tomorrow Low" ls 5, \
	"$avgt_fn" using 1:4 with linespoints title "Tomorrow Average" ls 6
EOF

# Delete the files
rm $avgc_fn
rm $avgt_fn
finished_plots+=("${plotName[1]}")

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
	set autoscale y
	$xtime
	$xyfonts
	set xtics font ',10'
	set xrange [time(0) - 7*24*60*60:time(0)]
	# tics for every 6 hours
	set xtics 60*60*6;
	# hide minor tics
	set xtics scale 1,0
	set ytics 1	
	$png_size
	set output "${directory}/${plotName[2]}"
	set style line 1 lc rgb "#cc2455"
	plot "$cpu_fn" using 1:3 with lines notitle ls 1
EOF
	rm $cpu_fn
	finished_plots+=("${plotName[2]}")
fi

echo "Plots generated, saved in directory: $directory"
echo
for i in "${finished_plots[@]}"
do
	echo $i
done
echo
