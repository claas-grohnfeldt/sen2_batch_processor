#!/bin/bash

path_to_ROIs="/home/ga39yoz/data/s2SR/LCZ42/ROIs/ROIs.csv"

date_str="2018-02-12"

for date_str in "2017-02-12" "2017-05-02" "2017-08-29" "2017-11-25" "2018-01-21" "2018-03-30" "2018-06-15" "2018-08-14"; do
	echo "#######################"
	echo "# date_str = $date_str"
	echo "#######################"
	while IFS=, read -r scene_name lonA latA lonB latB; do
		lat=$(echo "0.5*($latA + $latB)" | bc -i | sed -n '$,$p')
		lon=$(echo "0.5*($lonA + $lonB)" | bc -i | sed -n '$,$p')
		#get_sunrise_sunset.sh $lon $lat $date_str
		sunrise_sunset=$(bash get_sunrise_sunset.sh $lon $lat $date_str)
		printf "sunrise/sunset=%s, lon=%s, lat=%s, scene_name=%s\n" "$sunrise_sunset" "$lon" "$lat" "$scene_name"
	done < "$path_to_ROIs"
done
