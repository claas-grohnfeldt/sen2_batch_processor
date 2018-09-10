#!/usr/bin/env bash

# load paths
. configure.sh


keep_L1C_zip_file=true
keep_L1C_unzipped_SAFE_folder=false

season="summer"

#path_to_sen2cor="/home/ga39yoz/data/s2SR/LCZ42/src/sen2cor/Sen2Cor-02.05.05-Linux64/bin/L2A_Process"
PATH_FILE_L2A_Process="${PATH_DIR_SEN2COR}/bin/L2A_Process"
#PATH_DIR_DATA_SEN2="${PATH_DIR_DATA}/sen2"
#PATH_LINK_SEN2COR_TO_BE_PROCESSED_LIST="$PATH_DIR_TMP/sen2core_to_be_processed.txt"
PATH_FILE_SEN2COR_TO_BE_PROCESSED_LIST="${PATH_LINK_SEN2COR_TO_BE_PROCESSED_LIST%.txt}_$(date +%y%m%d_%H%M%S).txt"

#path_to_target_dir_base="${PATH_DIR_MAIN}/data/sen2"

mode="interactive"
#   =interactive
#   =autonomous


echo "#################################################################################"
echo "#"
echo "#  sen2cor batch processing to generate L2A products"
echo "#"
echo "#################################################################################"
echo
echo "#################################"
echo "# Settings"
echo "#################################"
echo " PATH_FILE_L2A_Process = $PATH_FILE_L2A_Process"
echo " PATH_DIR_DATA_SEN2 = $PATH_DIR_DATA_SEN2"
echo " season = $season"
echo " mode = $mode"
echo " keep_L1C_zip_file = $keep_L1C_zip_file"
echo " keep_L1C_unzipped_SAFE_folder = $keep_L1C_unzipped_SAFE_folder"

# initialization
if [ $mode = interactive ]; then
	unzipItAlways=false
	unzipItNever=false
	
	deleteZipAlways=false
	deleteZipNever=false
	
	overwriteL2AAlways=false
	overwriteL2ANever=false

elif [ $mode = autonomous ]; then
	unzipItAlways=true
	unzipItNever=false
	
	if [ $keep_L1C_zip_file = true ]; then
		deleteZipAlways=false
		deleteZipNever=true
	else
		deleteZipAlways=true
		deleteZipNever=false
	fi
	
	overwriteL2AAlways=false
	overwriteL2ANever=true
fi

# make directory for FILE_SEN2COR_TO_BE_PROCESSED_LIST if it does not exit
mkdir -p ${PATH_FILE_SEN2COR_TO_BE_PROCESSED_LIST/\/$(basename $PATH_FILE_SEN2COR_TO_BE_PROCESSED_LIST)/}

for PATH_SCENE in ${PATH_DIR_DATA_SEN2}/*; do
	echo
	echo "***********************************************************************"
	echo "* Processing scene:"
	echo "* $PATH_SCENE"
	echo "* Season:"
	echo "* $season"
	echo "***********************************************************************"
	echo
	PATH_DIR_TILES="${PATH_SCENE}/${season}/tiles"
	if [ -d $PATH_DIR_TILES ]; then
		echo "  +++++++++"
		echo "  + STEP 1: Iterating through zip-compressed L1C .SAFE.zip data files (if any) and unzip ..."
		echo "  +++++++++"
		cd $PATH_DIR_TILES
		if [ -z "$(ls -A *MSIL1C_*.SAFE.zip 2>/dev/null)" ]; then
			echo "    No zip-compressed L1C products found in this directory:"
			echo "    $PWD"
		else
			for PATH_FILE_TILE_ZIP in *MSIL1C*.SAFE.zip; do
				if [ -f $PATH_FILE_TILE_ZIP ]; then
					echo
					echo "  #-------------------------------------------------------------------"
					echo "  # Tile/product: "
					echo "  # $(basename $PATH_FILE_TILE_ZIP)"
					echo "  #-------------------------------------------------------------------"
					#skipL1CPruduct=false

					# check if corresponding unzipped L1C product folder already exists in the directory
					PATH_DIR_TILE_L1C=${PATH_FILE_TILE_ZIP%*.zip}
					if [ -d $PATH_DIR_TILE_L1C ]; then
						echo "    Corresponding L1C directory already exist:"
						echo "    '$PWD/$PATH_DIR_TILE_L1C'"
						printf "    Checking L1C folder roughly for completeness ... "
						if ( ! [ -z "$(ls -A $PATH_DIR_TILE_L1C 2>/dev/null)" ] &&
						     ! [ -z "$(ls -A $PATH_DIR_TILE_L1C/DATASTRIP 2>/dev/null)" ] &&
						     ! [ -z "$(ls -A $PATH_DIR_TILE_L1C/GRANULE 2>/dev/null)" ] &&
						     ! [ -z "$(ls -A $PATH_DIR_TILE_L1C/HTML 2>/dev/null)" ] &&
						     [ -d "$PATH_DIR_TILE_L1C/AUX_DATA" ] &&
						     [ -f "$PATH_DIR_TILE_L1C/MTD_MSIL1C.xml" ] &&
						     [ -f "$PATH_DIR_TILE_L1C/INSPIRE.xml" ] &&
						     [ -f "$PATH_DIR_TILE_L1C/manifest.safe" ] ); then
							echo "seems to be OK."
							
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
							if ! $unzipItAlways && ( $unzipItNever || [[ $unzipIt == n || $unzipIt == no ]] ); then
								echo "    Skipping unzipping this L1C file."
								continue
							fi
						else 	
							echo "problem detected!"
							echo "    Warning: The folder"
							echo "    '$PWD/$PATH_DIR_TILE_L1C'"
							echo "    seems not to be a complete .SAFE directory / Sentinel-2 L1C product!"
							echo "    Will be overwritten by content of compressed zip-file!"
							continue
						fi
					fi

					printf "    Checking compressed data ... "
					if [ "$(unzip -t $PATH_FILE_TILE_ZIP) | grep 'No errors detected in compressed data')" ]; then 
						printf "all good.\n"
						unzipIt="yes"
						# if [ -d "${PATH_FILE_TILE_ZIP%*.zip}" ]; then 
						# 	echo "    Directory already exists:"
						# 	echo "    ${PATH_FILE_TILE_ZIP%*.zip}"
						# 	echo
						# 	unzipIt="no"
						# 	#read -p "  > Would you like to proceed unzipping and overwrite existing data? (Y/N) [N]: " unzipIt
						# 	if ! $unzipItAlways && ! $unzipItNever; then
						# 		read -p "  > Would you like to proceed unzipping and OVERWRITE existing data? [y]es [n]o [A]lways [N]ever (default [n]): " unzipIt
						# 		if ! [ $unzipIt ]; then 
						# 			echo "    Using default value [n]"; 
						# 			unzipIt="n"
						# 		fi
						# 		if [[ $unzipIt == A || $unzipIt == Always ]]; then
						# 			unzipItAlways=true
						# 		elif [[ $unzipIt == N || $unzipIt == Never ]]; then
						# 			unzipItNever=true
						# 		fi
						# 	fi
						# fi
						# if ! ( [ -d "${PATH_FILE_TILE_ZIP%*.zip}" ] && $unzipItNever ) && ( $unzipItAlways || [[ $unzipIt == y || $unzipIt == yes ]] ); then
						printf "    Unzipping ... "
						unzip -oq $PATH_FILE_TILE_ZIP
						echo "done."
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
						echo "  Errors found in zipped data!"
						echo "  This data cannot be processed. Skipping this tile."
						echo "  Please check this data manually!!"
						continue
					fi
				fi
			done
		fi
		echo
		echo "  +++++++++"
		echo "  + STEP 2: Iterating through L1C .SAFE data folders and create a list of L1C products"
		echo "  +         to be processed (in parallel) via sen2cor to generate corresponding L2A data ..."
		echo "  +++++++++"
		# echo "  ##################################"
		# echo "  # Sen2Cor processing .."
		# echo "  ##################################"
				
		# ls *.zip
		#pwd
		#ls *L1C*.zip
		#unzip *L1C*.zip
		# for tileZip in $PATH_DIR_TILES/*.zip; do
		# 	
		# 	if ! [ -d ${tileZip##*.} ]; then
		# 		unzip 
		# 	fi
		# done
		
		# for PATH_FILE_TILE_ZIP in *L1C*.SAFE.zip; do
		for PATH_DIR_TILE_L1C in *MSIL1C_*.SAFE; do
			echo
			echo "    #-------------------------------------------------------------------"
			echo "    # Tile/product: $(basename $PATH_DIR_TILE_L1C)"
			echo "    #-------------------------------------------------------------------"
			printf "    Checking L1C folder roughly for completeness ... "
			if ( [ -d $PATH_DIR_TILE_L1C ] &&
			     ! [ -z "$(ls -A $PATH_DIR_TILE_L1C 2>/dev/null)" ] &&
			     ! [ -z "$(ls -A $PATH_DIR_TILE_L1C/DATASTRIP 2>/dev/null)" ] &&
			     ! [ -z "$(ls -A $PATH_DIR_TILE_L1C/GRANULE 2>/dev/null)" ] &&
			     ! [ -z "$(ls -A $PATH_DIR_TILE_L1C/HTML 2>/dev/null)" ] &&
			     [ -f "$PATH_DIR_TILE_L1C/MTD_MSIL1C.xml" ] &&
			     [ -f "$PATH_DIR_TILE_L1C/INSPIRE.xml" ] &&
			     [ -f "$PATH_DIR_TILE_L1C/manifest.safe" ] ); then
				echo "seems to be OK."

				# check if the corresponding L2A product already exists in the directory
				PATH_DIR_TILE_L2A=${PATH_DIR_TILE_L1C/MSIL1C_/MSIL2A_}
				if [ -d $PATH_DIR_TILE_L2A ]; then
					echo "    Corresponding L2A folder already exist:"
					echo "    '$PATH_DIR_TILE_L2A'"
					printf "    Checking L2A folder roughly for completeness ... "
					if ( ! [ -z "$(ls -A $PATH_DIR_TILE_L2A 2>/dev/null)" ] && \
                                              ! [ -z "$(ls -A $PATH_DIR_TILE_L2A/DATASTRIP 2>/dev/null)" ] && \
                                              ! [ -z "$(ls -A $PATH_DIR_TILE_L2A/GRANULE 2>/dev/null)" ] && \
                                              ! [ -z "$(ls -A $PATH_DIR_TILE_L2A/HTML 2>/dev/null)" ] && \
                                              [ -f "$PATH_DIR_TILE_L2A/MTD_MSIL2A.xml" ] && \
                                              [ -f "$PATH_DIR_TILE_L2A/INSPIRE.xml" ] && \
                                              [ -f "$PATH_DIR_TILE_L2A/manifest.safe" ] ); then
						echo "seems to be OK."
						if ! $overwriteL2AAlways && ! $overwriteL2ANever; then
							echo "  > Do you wish to generate a new L2A product (using sen2cor) under the same name?"
							read -p "    (warning: This would OVERWRITE the existing L2A product) [y]es [n]o [A]lways [N]ever (default [n]): " overwriteL2A
							if ! [ $overwriteL2A ]; then
								overwriteL2A="n"
								echo "    Using default value [n]"
							fi
							if [[ $overwriteL2A == A || $overwriteL2A == Always ]]; then 
								overwriteL2AAlways=true
							fi
							if [[ $overwriteL2A == N || $overwriteL2A == Never ]]; then
								overwriteL2ANever=true
							fi
						fi
						if ! $overwriteL2AAlways && ( $overwriteL2ANever || [[ $overwriteL2A == n || $overwriteL2A == no ]] ); then
							echo "    Skipping unzipping this L1C file."
							continue
						fi
					else 	
						echo "problem detected!"
						echo "    Warning: The folder"
						echo "    '$PATH_DIR_TILE_L2A'"
						echo "    seems not to be a complete .SAFE folder / Sentinel-2 L2A product!"
						echo "    This L1C data will be added to the list of L2A products to be generated via sen2cor."
						# continue
					fi
				fi
				echo "    Upating the file"
				echo "    '$PATH_FILE_SEN2COR_TO_BE_PROCESSED_LIST'"
				echo "    by adding"
				echo "    '$PWD/$PATH_DIR_TILE_L1C'"
				printf "    to the list of L1C products to be processed via sen2cor ... "
				echo "$PWD/$PATH_DIR_TILE_L1C" >> $PATH_FILE_SEN2COR_TO_BE_PROCESSED_LIST
				echo "done."
				echo "    Create symbolic link '$PATH_LINK_SEN2COR_TO_BE_PROCESSED_LIST' to file '$PATH_FILE_SEN2COR_TO_BE_PROCESSED_LIST' ... "
				ln -sf $PATH_FILE_SEN2COR_TO_BE_PROCESSED_LIST $PATH_LINK_SEN2COR_TO_BE_PROCESSED_LIST
				echo "done."
			else 
				echo "    Warning: '$PATH_DIR_TILE_L1C' seems not to be complete .SAFE folder / Sentinel-2 product!"
				echo "    This data cannot be processed. Skipping this tile."
				echo "    Please check that data/directory manually and possibly re-unzip "
				echo "    the corresponding .SAFE.zip file or even re-download it!"
				echo
				continue
			fi
		done
		cd - > /dev/null
	else
		echo "Error: No such directory: '${PATH_DIR_TILES}'"
		echo "Abording now."
		echo
		exit
	fi
done
