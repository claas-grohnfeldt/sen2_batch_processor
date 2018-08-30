#!/bin/bash

function convert_12h_to_24h() {
	if [[ "$1" = *"am"* ]]; then
		echo "$(date --date="`echo "0${1%:*}" | awk '{ print $1}'` AM" +%R)"
	else
		echo $(date --date="`echo ${1%:*} | awk '{ print $1}'` PM" +%R)
	fi
}

lon=$1
lat=$2
date_str=$3

date_year=${date_str%%-*}
date_month=$(echo ${date_str#*-} | sed 's/-.*$//' | sed 's/^0//')
date_day=${date_str##*-} 

sunrise_sunset_url="https://sunrise-sunset.org/search?location=${lon},${lat}&year=${date_year}&month=${date_month}#calendar"

if ! [[ $(curl -s "${sunrise_sunset_url}") ]]; then
    printf "no sunrise/sunset data available for location (lon,lat)=(%s, %s)\n" "$lon" "$lat"
    exit 1
fi
time_sunrise=$(curl -s "${sunrise_sunset_url}" | sed -n '/Sunrise time '"${date_str}"'/,$p' | sed -n '1,1p' | sed -e 's/^.*Sunrise time//' | sed "s/^.*'>//" | sed 's/<.*$//')
time_sunset=$(curl -s "${sunrise_sunset_url}" | sed -n '/Sunset time '"${date_str}"'/,$p' | sed -n '1,1p' | sed -e 's/^.*Sunset time//' | sed "s/^.*'>//" | sed 's/<.*$//')

time_sunrise24h=$(convert_12h_to_24h "$time_sunrise")
time_sunset24h=$(convert_12h_to_24h "$time_sunset")
echo "$time_sunrise24h $time_sunset24h"
