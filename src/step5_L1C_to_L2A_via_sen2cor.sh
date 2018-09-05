#!/usr/bin/env bash

# load paths
. configure.sh


keep_L1C_zip_file=false
keep_L1C_unzipped_SAFE_folder=false

season="summer"

#path_to_sen2cor="/home/ga39yoz/data/s2SR/LCZ42/src/sen2cor/Sen2Cor-02.05.05-Linux64/bin/L2A_Process"
PATH_FILE_L2A_Process="${PATH_DIR_SEN2COR}/bin/L2A_Process"
PATH_DIR_DATA_SEN2="${PATH_DIR_DATA}/sen2"

#path_to_target_dir_base="${PATH_DIR_MAIN}/data/sen2"


# initialization
unzipItAlways=false
unzipItNever=false

deleteZipAlways=false
deleteZipNever=false

# overwrite_SAFE_file_Always=false
# overwrite_SAFE_file_Never=false

for PATH_SCENE in ${PATH_DIR_DATA_SEN2}/*; do
	echo
	echo "#**********************************************************************"
	echo "#"
	echo "# Processing scene: $PATH_SCENE"
	echo "#"
	echo "#**********************************************************************"
	PATH_DIR_TILES="${PATH_SCENE}/${season}/tiles"
	if [ -d $PATH_DIR_TILES ]; then
		cd $PATH_DIR_TILES
		if [ -z "$(ls -A *MSIL1C_*.SAFE.zip 2>/dev/null)" ]; then
			echo "  No zip-compressed L1C products found in this directory:"
			echo "  $PWD"
		else
			echo "  #######################################"
			echo "  # Unzipping zip-compressed L1C data .."
			echo "  #######################################"
			for PATH_FILE_TILE_ZIP in *MSIL1C*.SAFE.zip; do
				if [ -f $PATH_FILE_TILE_ZIP ]; then
					echo
					echo "  #-------------------------------------------------------------------"
					echo "  # Tile/product: "
					echo "  # $(basename $PATH_FILE_TILE_ZIP)"
					echo "  #-------------------------------------------------------------------"
					printf "    Checking compressed data ... "
					if [ "$(unzip -t $PATH_FILE_TILE_ZIP) | grep 'No errors detected in compressed data')" ]; then 
						printf "all good.\n"
						echo
						unzipIt="yes"
						if [ -d "${PATH_FILE_TILE_ZIP%*.zip}" ]; then 
							echo "    Directory already exists:"
							echo "    ${PATH_FILE_TILE_ZIP%*.zip}"
							echo
							unzipIt="no"
							#read -p "  > Would you like to proceed unzipping and overwrite existing data? (Y/N) [N]: " unzipIt
							if ! $unzipItAlways && ! $unzipItNever; then
								read -p "  > Would you like to proceed unzipping and OVERWRITE existing data? [y]es [n]o [A]lways [N]ever (default [n]): " unzipIt
								if ! [ $unzipIt ]; then 
									echo "    Using default value [n]"; 
									unzipIt="n"
								fi
								if [[ $unzipIt == A || $unzipIt == Always ]]; then
									unzipItAlways=true
								elif [[ $unzipIt == N || $unzipIt == Never ]]; then
									unzipItNever=true
								fi
							fi
						fi
						if ! ( [ -d "${PATH_FILE_TILE_ZIP%*.zip}" ] && $unzipItNever ) && ( $unzipItAlways || [[ $unzipIt == y || $unzipIt == yes ]] ); then
							printf "    Unzipping ... "
							unzip -oq $PATH_FILE_TILE_ZIP
							echo " done."
							echo
							if ! $keep_L1C_zip_file && ! $deleteZipNever; then
								echo "    The variable 'keep_L1C_zip_file' is set to ${keep_L1C_zip_file} in 'configure.sh'."
								echo "    About to permanently delete file $PATH_FILE_TILE_ZIP .."
								if $deleteZipAlways; then
									rm $PATH_FILE_TILE_ZIP
									echo "    File has been removed."
								else
									read -p "  > Should it really be deleted? [y]es [n]o [A]lways [N]ever (default [n]): " deleteZip
									if ! [ $deleteZip ]; then 
										echo "    Using default value [n]"; 
										deleteZip="n"
									fi
									if [[ $deleteZip == A || $deleteZip == Always ]]; then
										deleteZipAlways=true
									elif [[ $deleteZip == N || $deleteZip == Never ]]; then
										deleteZipNever=true
									fi
									
									if ! $deleteZipNever && ( $deleteZipAlways || [[ $deleteZip == y || $deleteZip == yes ]] ); then
										rm $PATH_FILE_TILE_ZIP
										echo "    File has been removed."
									else
										echo "    File was kept."
									fi
								fi
							fi
						else
							echo "    Not unzipped."
						fi
					else
						printf "  Errors found in zipped data!\n"
						echo
						echo "  This data cannot be processed. Skipping this tile."
						echo
						echo "  Please check this data manually!!"
						echo
						continue
					fi
				fi
			done
		fi
		# echo
		# echo "  ##################################"
		# echo "  # Sen2Cor processing .."
		# echo "  ##################################"
		# echo
		# 		
		# # ls *.zip
		# #pwd
		# #ls *L1C*.zip
		# #unzip *L1C*.zip
		# # for tileZip in $PATH_DIR_TILES/*.zip; do
		# # 	
		# # 	if ! [ -d ${tileZip##*.} ]; then
		# # 		unzip 
		# # 	fi
		# # done
		# 
		# for PATH_FILE_TILE_ZIP in *L1C*.SAFE.zip; do
		# 	if [ -f $PATH_FILE_TILE_ZIP ]; then
		# 		echo
		# 		echo "#-------------------------------------------------------------------"
		# 		echo "# Tile/product: $(basename $PATH_FILE_TILE_ZIP)"
		# 		echo "#-------------------------------------------------------------------"
		# 		printf "Checking cpompressed data ... "
		# 		if [ "$(unzip -t $PATH_FILE_TILE_ZIP) | grep 'No errors detected in compressed data')" ]; then 
		# 			printf "all good.\n"
		# 			echo
		# 			echo "===> Unzipping ..."
		# 			unzip $PATH_FILE_TILE_ZIP
		# 			echo "<=== done."
		# 			echo
		# 			echo "===> sen2cor processing ..."
		# 			$PATH_FILE_L2A_Process ${PATH_FILE_TILE_ZIP%.zip}
		# 			echo "<=== done."
		# 		else 
		# 			printf "errors found in zipped data!\n"
		# 			echo
		# 			echo "This data cannot be processed. Skipping this tile."
		# 			echo
		# 			echo "Please check this data manually!!"
		# 			echo
		# 			continue
		# 		fi
		# 	fi
		# done
		cd - > /dev/null
	else
		echo
		echo "Error: No such directory: '${PATH_DIR_TILES}'"
		echo 
		echo "Abording now."
		echo
		exit
	fi
done
