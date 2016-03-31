#!/bin/bash

# Usage:
# ./seat_watcher.sh crn1 crn2 crn3 ... crnn

# Depends on mail from mailutils
# install via:
#     sudo apt-get install mailutils

email_address="your_email@provider.com"

term=201608
base_url="https://oscar.gatech.edu/pls/bprod/bwckschd.p_disp_detail_sched?term_in=$term&crn_in="

# Takes crn as string and returns proper url.
# Usage: crn_to_url 91185
crn_to_url() {
    echo $base_url$1
}

parse_data() {
    while read data;
    do
    	echo $data
    done
}

pipe_to_array() {
    declare -a parsed_data
    i=0
    while read data;
    do
	parsed_data[$i]=$data
	i=$i+1
    done

    name=${parsed_data[0]}
    remaining_seats=${parsed_data[8]}
    waitlist_remaining=${parsed_data[12]}

    if [[ $remaining_seats != "0" || $waitlist_remaining != "0" ]]
    then
	echo $name: Remaining: $remaining_seats Waitlist Remaining: $waitlist_remaining | mail -s "Remaining Seats Update" $email_address
    fi
}


while true
do
    for crn in $@
    do
	crn_to_url $crn | xargs curl 2>/dev/null | grep -E "<t.*CLASS=\"dd"| sed 's/<[^>]*>//g' | pipe_to_array
    done
    sleep 30
done
