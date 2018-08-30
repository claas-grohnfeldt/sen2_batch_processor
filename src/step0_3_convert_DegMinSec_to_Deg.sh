#!/bin/bash

degMinSec2Deg(){
    echo "scale=6; ($1) + ($2 / 60) + ($3 / 3600)" | bc -l | sed 's/^\./0./'
}
pathToROIOutputFile="../ROIs/ROIs_all.csv"
> $pathToROIOutputFile
#f=pure_ROIs/ROI_LCZ42addon_22956_Chicago_spring.txt
for f in ../ROIs/pure_ROIs/*spring.txt; do
	fnew=${f%.txt}_COMPLETE.txt
	more $f
	cp $f $fnew
	desc=${f%_spring.txt*}
	desc=${desc#*ROI_}
	nextline=$desc
	for corner in "Upper Left" "Lower Left" "Upper Right" "Lower Right"; do
		line=$(grep "$corner" $f)
		tmp=${line#*) (}
		tmp=${tmp%)}
		lonChar=''
		lonLeadSign=''
		if [[ $line = *'E'* ]]; then
			lonChar='E'
		
		elif [[ $line = *'W'* ]]; then
			lonChar='W'
			lonLeadSign='-'
		else 
			>&2 echo "ERROR: No longitude direction character (W or E) found!"
		fi
		latChar=''
		latLeadSign=''
		if [[ $line = *'N'* ]]; then
			latChar='N'
		elif [[ $line = *'S'* ]]; then
			latChar='S'
			latLeadSign='-'
		else 
			>&2 echo "ERROR: No latitude direction character (N or S) found!"
		fi

		#lonFullStr=${tmp%W*}
		lonFullStr=${tmp%${lonChar}*}
		latFullStr=${tmp#*, }
		latFullStr=${latFullStr%${latChar}*}
			
		d=${latFullStr%d*}
		tmp=${latFullStr#*d}
		m=${tmp%\'*}
		tmp=${latFullStr#*\'}
		s=${tmp%\"*}
		latDeg=$(degMinSec2Deg $d $m $s)

		d=${lonFullStr%d*}
		tmp=${lonFullStr#*d}
		m=${tmp%\'*}
		tmp=${lonFullStr#*\'}
		s=${tmp%\"*}
		lonDeg=$(degMinSec2Deg $d $m $s)
		
		# sed -i "/${corner}/s/$/ (${lonDeg}${lonChar}, ${latDeg}${latChar})/"  $fnew
		sed -i "/${corner}/s/$/ (${lonLeadSign}${lonDeg},${latLeadSign}${latDeg})/"  $fnew

		if [ "$corner" = "Upper Left" ] || [ "$corner" = "Lower Right" ]; then
			nextline="${nextline},${lonLeadSign}${lonDeg},${latLeadSign}${latDeg}"
		fi
	done
	echo ${nextline} >> ${pathToROIOutputFile}
	echo "->"
	more $fnew
done

