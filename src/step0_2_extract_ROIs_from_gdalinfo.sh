#!/bin/bash

#mkdir ../ROIs/pure_ROIs
for f in ../ROIs/full_gdalinfo_sen2/*.txt; do
	#echo $f
	#echo ${f#*gdalinfo_sen2\/}
	ROI_file=../ROIs/pure_ROIs/ROI_${f#*gdalinfo_sen2\/}
	#echo $ROI_file
	echo ${f%.txt} > $ROI_file
	grep --after-context=4 "Corner Coord" $f >> $ROI_file;
done
