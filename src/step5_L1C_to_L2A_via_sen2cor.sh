#!/usr/bin/env bash

path_to_sen2cor="/home/ga39yoz/data/s2SR/LCZ42/src/sen2cor/Sen2Cor-02.05.05-Linux64/bin/L2A_Process"

path_to_target_dir_base="/home/ga39yoz/data/s2SR/LCZ42/data/sen2_kop"
season="summer"

for path_scene in $path_to_target_dir_base/*; do
	path_to_target_dir="${path_scene}/${season}/tiles"
	if [ -d $path_to_target_dir ]; then
		cd $path_to_target_dir
		# ls *.zip
		pwd
		#ls *L1C*.zip
		#unzip *L1C*.zip
		# for tileZip in $path_to_target_dir/*.zip; do
		# 	
		# 	if ! [ -d ${tileZip##*.} ]; then
		# 		unzip 
		# 	fi
		# done
		for tileZipFile in *.SAFE.zip; do
			if [ -f $tileZipFile ]; then
				unzip $tileZipFile
				echo $tileFipFile
				$path_to_sen2cor ${tileZipFile%.zip}
			fi
		done
		cd - > /dev/null
	fi
done
