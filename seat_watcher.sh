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

pack_seats() {
    echo "$1;$2"
}

# Usage:
#    compare_seats "packed;seats" remaining waitlist
check_seats_differ() {

    if [[ $# -lt 3 ]]
    then
	echo "First time" >&2
	echo true
	return
    fi

    old_seats=(${1//;/ })

    if [[ ${old_seats[0]} != $2 ]]
    then
	echo true
	return
    fi

    if [[ ${old_seats[1]} != $3 ]]
    then
	echo true
	return
    fi

    echo false
}

declare -A persist

notify_user() {
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
	if [[ `check_seats_differ ${persist["$name"]} $remaining_seats $waitlist_remaining` == true ]]
	then
	    echo "Sending mail" >&2
	    echo $name: Remaining: $remaining_seats Waitlist Remaining: $waitlist_remaining | mail -s "Remaining Seats Update" $email_address
	else
	    echo "No difference found" >&2
	fi
    fi

    echo "$name;$remaining_seats;$waitlist_remaining"
}



while true
do
    for crn in $@
    do
	updates=`crn_to_url $crn | xargs curl 2>/dev/null | grep -E "<t.*CLASS=\"dd"| sed 's/<[^>]*>//g' | notify_user`
	name=`expr match "$updates" '\([^;]*\)'`
	seats=`expr match "$updates" '[^;]*;\(.*\)'`
	persist["$name"]=$seats
    done
    sleep 5
done
