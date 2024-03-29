#!/bin/bash
# Make sure that commands which fail will cause the shell script to exit immediately
set -e 

# load paths
. configure.sh

#parentIdentifier=EOP:CODE-DE:S1_SAR_L1_GRD
parentIdentifier="EOP:CODE-DE:S2_MSI_L1C"
#parentIdentifier="EOP:CODE-DE:S2_MSI_L2A"

cloudCoverMinPerc=0
cloudCoverMaxPerc=100

daylight_acquisitions_only=false

batchSize=999
downloadParallel=2

#curlOpts="--netrc -Lk --cookie-jar /tmp/t"
curlOpts="--netrc-file $PATH_FILE_NETRC -Lk --cookie-jar /tmp/t"

season="summer"
# specify season time periods
if [ "$season" = "autumn" ]; then
	startDate="2017-09-01T00:00:00.001Z"
	endDate="2017-11-30T23:59:59.999"
elif [ "$season" = "winter" ]; then
	startDate="2017-12-01T00:00:00.001Z"
	endDate="2018-02-28T23:59:59.999"
elif [ "$season" = "spring" ]; then
	startDate="2018-03-01T00:00:00.001Z"
	endDate="2018-05-30T23:59:59.999"
elif [ "$season" = "summer" ]; then
	startDate="2018-06-01T00:00:00.001Z"
	endDate="2018-08-31T23:59:59.999"
fi

# make sure that code-de download script is available at location specified in 'configure.sh'
if ! [ -f $PATH_FILE_CodeDE_query_download ]; then
   echo "code-de download script does not exist at location specified in 'configure.sh':"
   echo "$PATH_FILE_CodeDE_query_download ('no such file exists in file system')"
   echo "Forgot to run 'bash install.sh'? Or changed folder structure since running 'bash install.sh'?"
   echo "Abording now."
   exit 1
fi

printf "###############################################\n"
printf "#\n"
printf "# 1) Identifying and downloading data\n"
printf "#\n"
printf "###############################################\n"
path_current_dir=$(pwd)

while read -r fullline || [[ -n "$fullline" ]]; do
    # echo "- line read from ROI.csv file: $fullline"
	# extract scene name
	scene_name=${fullline%%,*}
	line_latlon=${fullline#*,}
	# extract coordinates according to the following naming convention:
	#    lon= "longitude coordinate in degrees"
	#    lat= "latitude coordinate in degrees"
	#    UL= "upper left corner"
	#    LR= "lower right corner"
	lon_UL=${line_latlon%%,*}
	# echo "line_latlon = $line_latlon"
	# echo "lon_UL = $lon_UL"
	# echo "line = $line"
	line=${line_latlon#*,}
	# echo "line = $line"
	lat_UL=${line%%,*}
	# echo "lat_UL = $lat_UL"
	line=${line#*,}
	# echo "line = $line"
	lon_LR=${line%%,*}
	# echo "lon_LR = $lon_LR"
	line=${line#*,}
	# echo "line = $line"
	lat_LR=${line%%,*}
	# echo "lat_LR = $lat_LR"

    # The center coordinates will be used later to query information about 
    # sunset and sunrise times.
    ROI_center_lat=$(echo "0.5*($lat_UL + $lat_LR)" | bc -i | sed -n '$,$p')
    ROI_center_lon=$(echo "0.5*($lon_UL + $lon_LR)" | bc -i | sed -n '$,$p')

    path_to_target_dir="${PATH_DIR_DATA_SEN2}/${scene_name}/${season}/tiles"
    path_to_target_dir_aux="${path_to_target_dir}/aux"

    AOI=$(echo "$lon_UL,$lat_UL,$lon_LR,$lat_LR")
    
    mkdir -p ${path_to_target_dir_aux}
    cd ${path_to_target_dir}
    
    # TODO: 4 lines added without testing
    path_to_ROI="${PATH_DIR_DATA_SEN2}/${scene_name}/ROI.csv"
    if ! [ -f $path_to_ROI ]; then
        echo $line_latlon > $path_to_ROI
    fi

    # copy both stdout and stderr to log file
    exec >/dev/tty
    exec >  >(tee -i $path_to_target_dir/stdout_stderr.log)
    #exec 2> >(tee -i $path_to_target_dir/stderr.log)
    exec 2>&1
	
    echo 
    echo "#*******************************"
	echo "#   Processing scene/ROI: " 
	echo "#   ${fullline}" 
	echo "#*******************************"
    echo "- target directory: $path_to_target_dir"
    
    printf "ROI upper left corner: (lat,lon)=(%s, %s)\n" "$lat_UL" "$lon_UL"
    printf "ROI lower right corner: (lat,lon)=(%s, %s)\n" "$lat_LR" "$lon_LR"
    printf "ROI coordinates: (lat,lon)=(%s, %s)\n" "$ROI_center_lat" "$ROI_center_lon"

    echo
	echo "----------------------------------------------------------------------------"
    echo "1.1)  For each ROI, identify all candidate products (tiles)"
    echo "----------------------------------------------------------------------------"

	CONSTRAINTS=$(echo "parentIdentifier=${parentIdentifier}&startDate=${startDate}&endDate=${endDate}&bbox=${AOI}&maximumRecords=${batchSize}&cloudCover=\[0,${cloudCoverMaxPerc}\]")
	echo "- query contraints:"
	echo ${CONSTRAINTS}
	queryOut=$($PATH_FILE_CodeDE_query_download -c "${CONSTRAINTS}" --noTransfer)

	# The following code assumes the following sentinel procuct file naming convention:
	# MMM_MSIL1C_YYYYMMDDHHMMSS_Nxxyy_ROOO_Txxxxx_<Product Discriminator>.SAFE
	echo "mission ID, product level, sensing date, sensing time, processing baseline number, relative orbit number, tile ID" > ${path_to_target_dir_aux}/candidate_tiles_all_info.csv
    > ${path_to_target_dir_aux}/candidate_tiles_all.txt

	if [[ $queryOut = *"No products found"* ]]; then
		echo "ERROR: No products found!"
		command || exit 1
	fi
	queryOut=${queryOut#*downloading...}
	D="curl -O " # multi-character delimiter
	#Split the String into Substrings
	unset sList
    sList=($(echo $queryOut | sed -e 's/'"$D"'/\n/g' | while read line; do echo $line | sed 's/[\t ]/'"$D"'/g'; done))

    unset tiles
	for (( i = 0; i < ${#sList[@]}; i++ )); do
        # echo
		# sList[i]=$(echo ${sList[i]} | sed 's/'"$D"'/ /')
        # echo "bp2: sList[i]:"
        # echo "${sList[i]}"
		tmp_tile_name=${sList[i]#*_T}
		tiles[i]=${tmp_tile_name%%_*}
        echo "i=${i}: sList[i]: ${sList[i]}  ##  tiles[i]: ${tiles[i]}"

		line_trimmed=${sList[i]#*download/}
		missionID=${line_trimmed%%_*}
		line_trimmed=${line_trimmed#*_}
		productLevel=${line_trimmed%%_*}
		line_trimmed=${line_trimmed#*_}
		sensingDate=${line_trimmed%%T*}
		line_trimmed=${line_trimmed#*T}
		sensingTime=${line_trimmed%%_*}
		line_trimmed=${line_trimmed#*_N}
		ProcessingBaselineNumber=${line_trimmed%%_*}
		line_trimmed=${line_trimmed#*_R}
		RelativeOrbitNumber=${line_trimmed%%_*}
		line_trimmed=${line_trimmed#*_T}
		TileNumber=${line_trimmed%%_*}
		echo "${missionID}, ${productLevel}, ${sensingDate}, ${sensingTime}, ${ProcessingBaselineNumber}, ${RelativeOrbitNumber}, ${TileNumber}" >> ${path_to_target_dir_aux}/candidate_tiles_all_info.csv
	done
	# Output the Split String
	echo "Number of products found: ${#sList[@]}"
	for (( i = 0; i < ${#sList[@]}; i++ )); do
		echo ${sList[i]} >> ${path_to_target_dir_aux}/candidate_tiles_all.txt
	done
    echo "Names of all candidate files are saved in the following file:"
    echo "${path_to_target_dir_aux}/candidate_tiles_all.txt"
	
	echo
    echo "----------------------------------------------------------------------------"
    echo "1.2)  Identify all unique tile IDs "
    echo "----------------------------------------------------------------------------"
	unset uniqueTileIDs
	uniqueTileIDs=($(for v in "${tiles[@]}"; do echo "$v";done| sort| uniq| xargs))
	echo "unique tile set = { ${uniqueTileIDs[@]} }"

    echo
    echo "----------------------------------------------------------------------------"
    echo "1.3)  Check if there there exist at least one daylight acquisition "
    echo "      for each tile ID. "
    echo "----------------------------------------------------------------------------"

    if [ "$daylight_acquisitions_only" = true ]; then
        for tileID in "${uniqueTileIDs[@]}"; do
            only_nighttime_acquisitions=true
            while IFS=', ' read -r missionIDTMP productLevelTMP sensingDateTMP sensingTimeTMP processingBaselineNumberTMP relativeOrbitNumberTMP tileIDTMP; do
                #re-format from YYYYMMDD to YYYY-MM-DD
                date_str="${sensingDateTMP:0:4}-${sensingDateTMP:4:2}-${sensingDateTMP:6:2}"
                sunrise_sunset_time=$(bash $PATH_DIR_SRC/get_sunrise_sunset.sh $ROI_center_lon $ROI_center_lat $date_str)
                time_str="${sensingTime:0:2}:${sensingTimeTMP:2:2}"
                is_daylight_acquisition=$(bash $PATH_DIR_SRC/check_if_time_in_range.sh $sunrise_sunset_time $time_str 30)
                if [[ "$is_daylight_acquisition" = true ]]; then
                    only_nighttime_acquisitions=false
                    break
                fi
            done <<< $(grep $tileID ${path_to_target_dir_aux}/candidate_tiles_all_info.csv)
            if [ "$only_nighttime_acquisitions" = true ]; then 
                echo "WARNING: No daylight product found for tileID=$tileID"
                echo "         Since the parameter 'daylight_acquisitions_only'"
                echo "         was set to 'true', this ROI is skipped entirely."
                echo "         The parent folder"
                echo "         ${PATH_DIR_DATA_SEN2}/${scene_name}"
                echo "         will be moved to"
                echo "         ${PATH_DIR_DATA_SEN2}/.scene_with_missing_daylight_acquisitions/${scene_name}"
                mkdir -p "${PATH_DIR_DATA_SEN2}/.scene_with_missing_daylight_acquisitions"
                mv "${PATH_DIR_DATA_SEN2}/${scene_name}" "${PATH_DIR_DATA_SEN2}/.scene_with_missing_daylight_acquisitions/${scene_name}"
                continue 2
            fi
        done
        echo "For each tile ID, daylight aquisitions have been found."
    else
        echo "Since the parameter 'daylight_acquisitions_only' was set to 'false',"
        echo "night-time acquisition are allowed. Hence, this step is skipped."
    fi

	echo
    echo "----------------------------------------------------------------------------"
    echo "1.4)  Find least cloudy product(s) for each previously identified tile ID"
    echo "      If desired (daylight_acquisitions_only=true), restrict procucts to daylight acquisitions "
    echo "----------------------------------------------------------------------------"
	cd ${path_to_target_dir_aux}
	echo "mission ID, product level, sensing date, sensing time, Processing Baseline number, Relative Orbit number, Tile Number, cloudCoverMax" > candidate_tiles_info.csv
    > adjacency_lists.csv
    maxNumDates=0
	for tileID in "${uniqueTileIDs[@]}"; do
		tmptxt=$(grep -A 30 "<name>$tileID</name>" $PATH_FILE_Sentinel2_tiling_grid_kml)
		tmptxt=${tmptxt#*Point>}
		tmptxt=${tmptxt#*coordinates>}
		tmptxt=${tmptxt%</Point>*}
		tmptxt=${tmptxt%</coordinates>*}
		centerPointLon=${tmptxt%%,*}
		tmptxt=${tmptxt#*,}
		centerPointLat=${tmptxt%,*}
        echo 
		echo "Tile ID = $tileID, centerPoint (lon,lat) = ($centerPointLon, $centerPointLat)"
		eps=0.0001

		lon_UL_tmp=$(echo "scale=6; $centerPointLon - $eps" | bc -l | sed 's/^\./0./')
		lat_UL_tmp=$(echo "scale=6; $centerPointLat + $eps" | bc -l | sed 's/^\./0./')
		lon_LR_tmp=$(echo "scale=6; $centerPointLon + $eps" | bc -l | sed 's/^\./0./')
		lat_LR_tmp=$(echo "scale=6; $centerPointLat - $eps" | bc -l | sed 's/^\./0./')

		AOI_cur_tile=$(echo "$lon_UL_tmp,$lat_UL_tmp,$lon_LR_tmp,$lat_LR_tmp")
		queryOutTMP='No products found'
		cloudCoverMaxPercTmp="-1"
		
		while ! [[ $queryOutTMP = *"_T${tileID}_"* ]] && [ $cloudCoverMaxPercTmp -lt ${cloudCoverMaxPerc} ]; do
			cloudCoverMaxPercTmp=$[$cloudCoverMaxPercTmp+1]
			echo "searching for products with cloudCoverMax = $cloudCoverMaxPercTmp .."
			CONSTRAINTS_tmp=$(echo "parentIdentifier=${parentIdentifier}&startDate=${startDate}&endDate=${endDate}&bbox=${AOI_cur_tile}&maximumRecords=${batchSize}&cloudCover=\[${cloudCoverMinPerc},${cloudCoverMaxPercTmp}\]")
			queryOutTMP=$($PATH_FILE_CodeDE_query_download -c "${CONSTRAINTS_tmp}" --noTransfer 2> /dev/null) 

            if [[ $queryOutTMP = *"_T${tileID}_"* ]]; then
                queryOutTMP=${queryOutTMP#*downloading...}
	            
                D="curl -O " # multi-character delimiter
	            #Split the String into Substrings
	            unset sList
                sList=($(echo $queryOutTMP | sed -e 's/'"$D"'/\n/g' | while read line; do echo $line | sed 's/[\t ]/'"$D"'/g'; done))

	            # The following code assumes the following sentinel procuct file
                # naming convention:
	            # MMM_MSIL1C_YYYYMMDDHHMMSS_Nxxyy_ROOO_Txxxxx_<Product Discriminator>.SAFE
                adjacency_list_line_head="$tileID, $centerPointLon, $centerPointLat, ${cloudCoverMaxPercTmp}"
                adjacency_list_line_tail=""
                numDates=0
                unset tiles
	            for (( i = 0; i < ${#sList[@]}; i++ )); do
	            	sList[i]=$(echo ${sList[i]} | sed 's/'"$D"'/ /')
	            	tmp_tile_name=${sList[i]#*_T}
	            	tiles[i]=${tmp_tile_name%%_*}

	            	line_trimmed=${sList[i]#*download/}
	            	missionID=${line_trimmed%%_*}
	            	line_trimmed=${line_trimmed#*_}
	            	productLevel=${line_trimmed%%_*}
	            	line_trimmed=${line_trimmed#*_}
	            	sensingDate=${line_trimmed%%T*}
	            	line_trimmed=${line_trimmed#*T}
	            	sensingTime=${line_trimmed%%_*}
	            	line_trimmed=${line_trimmed#*_N}
	            	ProcessingBaselineNumber=${line_trimmed%%_*}
	            	line_trimmed=${line_trimmed#*_R}
	            	RelativeOrbitNumber=${line_trimmed%%_*}
	            	line_trimmed=${line_trimmed#*_T}
	            	TileNumber=${line_trimmed%%_*}
	                echo "${missionID}, ${productLevel}, ${sensingDate}, ${sensingTime}, ${ProcessingBaselineNumber}, ${RelativeOrbitNumber}, ${TileNumber}, ${cloudCoverMaxPercTmp}" >> candidate_tiles_info.csv
                    #echo "+++++++ TileNumber=${TileNumber}, tileID=$tileID: "
                    if [[ ${TileNumber} = $tileID ]]; then
			            # If local time was, on that day, NOT during daylight 
                        # (i.e. before sunrise+1h or after sunset-1h), then set 
                        # queryOutTMP="No products found" (ignore this product (date))
                        if [ "$daylight_acquisitions_only" = true ]; then
                            #re-format from YYYYMMDD to YYYY-MM-DD
        			        date_str="${sensingDate:0:4}-${sensingDate:4:2}-${sensingDate:6:2}"
                            sunrise_sunset_time=$(bash $PATH_DIR_SRC/get_sunrise_sunset.sh $ROI_center_lon $ROI_center_lat $date_str)
                            time_str="${sensingTime:0:2}:${sensingTime:2:2}"
                            is_daylight_acquisition=$(bash $PATH_DIR_SRC/check_if_time_in_range.sh $sunrise_sunset_time $time_str 30)
                        else 
                            is_daylight_acquisition="true"
                        fi
                        if [[ "$is_daylight_acquisition" = "true" ]]; then
                            adjacency_list_line_tail="${adjacency_list_line_tail}, ${sensingDate}T${sensingTime}"
                            numDates=$((numDates + 1))
                            if (($numDates > $maxNumDates)); then
                                #echo "maxNumDates updated from $maxNumDates to $numDates"
                                maxNumDates=$numDates
                            fi
                        else
                            printf "WARNING: sensing time (${sensingTime}) was NOT at "
                            printf "daylight (between $sunrise_sunset_time). It is disregarded.\n"
                        fi
                    fi
	            done

                if (($numDates == 0)); then
                    queryOutTMP="No product found"
                fi
            fi
		done
        if [ $cloudCoverMaxPercTmp -eq ${cloudCoverMaxPerc} ]; then 
            printf "WARNING: for this tile, no product found that was acquired "
            printf "during daylight and has a cloudCover of less than the specified "
            printf "cloudCoverMaxPerc parameter, which was set to $cloudCoverMaxPerc. Because "
            printf "of this missing tile, the entire ROI will be skipped and the parent "
            printf "folder \n"
            printf "${PATH_DIR_DATA_SEN2}/${scene_name}\n"
            printf "will be moved to \n"
            mkdir -p "${PATH_DIR_DATA_SEN2}/.scene_with_missing_daylight_acquisitions"
            printf "${PATH_DIR_DATA_SEN2}/.scene_with_missing_daylight_acquisitions/${scene_name}"
            mv "${PATH_DIR_DATA_SEN2}/${scene_name}" "${PATH_DIR_DATA_SEN2}/.scene_with_missing_daylight_acquisitions/${scene_name}"
            # skip all further tile IDs corresponding to this ROI and continue 
            # straight with the next ROI:
            continue 2
        else
            adjacency_list_line="${adjacency_list_line_head}, ${numDates}${adjacency_list_line_tail}"
            echo "${adjacency_list_line}" >> adjacency_lists.csv
        fi
	done
    if [ $cloudCoverMaxPercTmp -lt ${cloudCoverMaxPerc} ]; then
        echo "product(s) found."
    fi
    csv_header="tile ID, centerPointLon, centerPointLat, cloudCoverMax, # dates"
    for ((j = 0; j < $maxNumDates; j++)); do
        csv_header="$csv_header, date $j"
    done
    csv_header="$csv_header\n"
    sed -i "1s/^/$csv_header/" adjacency_lists.csv
    cd - > /dev/null
	
	echo
    echo "----------------------------------------------------------------------------"
    echo "1.5)  Find best set of unique tiles"
    echo "----------------------------------------------------------------------------"

    python3 ${PATH_FILE_python_script_find_best_tiles} ${path_to_target_dir} ${maxNumDates}
	
    echo
	echo "----------------------------------------------------------------------------"
    echo "1.6)  Download tiles"
    echo "----------------------------------------------------------------------------"
    while IFS=, read -r tileID centerPointLon centerPointLat cloudCoverMaxTmp dateTmp; do
        echo "tileID: $tileID, centerPoint: ($centerPointLon, $centerPointLat), cloudCoverMax: $cloudCoverMaxTmp, date: $dateTmp"

        lon_UL_tmp=$(echo "scale=6; $centerPointLon - $eps" | bc -l | sed 's/^\./0./' | sed 's/^-\./-0./')
		lat_UL_tmp=$(echo "scale=6; $centerPointLat + $eps" | bc -l | sed 's/^\./0./' | sed 's/^-\./-0./')
		lon_LR_tmp=$(echo "scale=6; $centerPointLon + $eps" | bc -l | sed 's/^\./0./' | sed 's/^-\./-0./')
		lat_LR_tmp=$(echo "scale=6; $centerPointLat - $eps" | bc -l | sed 's/^\./0./' | sed 's/^-\./-0./')

        startDateTmp="${dateTmp//[ ]/T}.001Z"
        endDateTmp="${dateTmp//[ ]/T}.999Z"
		AOI_cur_tile=$(echo "$lon_UL_tmp,$lat_UL_tmp,$lon_LR_tmp,$lat_LR_tmp")
		CONSTRAINTS_tmp=$(echo "parentIdentifier=${parentIdentifier}&startDate=${startDateTmp}&endDate=${endDateTmp}&bbox=${AOI_cur_tile}&maximumRecords=${batchSize}&cloudCover=\[${cloudCoverMinPerc},${cloudCoverMaxTmp}\]")

		queryOutTMP=$($PATH_FILE_CodeDE_query_download -c "${CONSTRAINTS_tmp}" --noTransfer 2> /dev/null) 
		queryOutTMP=${queryOutTMP#*downloading...}
    	D="curl -O " # multi-character delimiter
    	#Split the String into Substrings
    	sList=($(echo $queryOutTMP | sed -e 's/'"$D"'/\n/g' | while read line; do echo $line | sed 's/[\t ]/'"$D"'/g'; done))
        mkdir $tileID
        cd $tileID
        echo 
        echo RUNNING THE FOLLOWING COMMANDs FOR DOWNLOADING:
        $PATH_FILE_CodeDE_query_download -c "${CONSTRAINTS_tmp}" -o "$curlOpts" -l=2
        lsout=$(ls)
        lsList=($(echo $lsout | sed -e 's/ /\n/g' | while read lsline; do echo $lsline; done))
        echo "keeping only the following file:"
        for (( i = 0; i < ${#lsList[@]}; i++ )); do
            #echo "  ${lsList[i]}"
            if [[ ${lsList[i]} = *"_T${tileID}_"* ]]; then
                echo "${lsList[i]}"
                mv ${lsList[i]} ../
            fi
        done
        cd ..
        rm -r $tileID
        echo
    done < ${path_to_target_dir}/tiles_info.csv

    cd $path_current_dir
    echo "********"
    echo "* done *"
    echo "********"
	echo
    exec >/dev/tty
done < "$PATH_FILE_ROIs"

echo "*********************"
echo "*     All done      *"
echo "*********************"
