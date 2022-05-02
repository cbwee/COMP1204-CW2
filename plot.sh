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

if [ $is_raspi = true ]; then
	gnuplot <<-EOL
	set title "CPU Temperature"
	EOL
fi
