#!/bin/bash

for fullpath in /datastore/exchange/sentinel/LCZ52_4train/*/spring/*.tif; do
	#for f in /datastore/exchange/sentinel/LCZ52_4train/${d}/spring/*; do
		echo ${fullpath}
		tmp=${fullpath#*4train\/}   # remove prefix
		a=${tmp%\/spring*}   # remove suffix
		output_file=$(echo "${a}_spring.txt")
		echo $output_file 
		gdalinfo ${fullpath} > ${output_file}
		echo ;
	#done;
done

#gdalinfo /datastore/exchange/sentinel/LCZ52_4train/LCZ42_204371_Munich/spring/204371_spring.tif > LCZ42_204371_Munich_204371_spring.txt
