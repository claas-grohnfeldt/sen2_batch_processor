#!/bin/bash

echo
printf "###############################################\n"
printf "#\n"
printf "# 2) downloading missing data\n"
printf "#\n"
printf "###############################################\n"

# load paths
. configure.sh

parallel=1
#PATH_DIR_DATA_SEN2="/home/ga39yoz/data/s2SR/LCZ42/data/sen2_kop"
#curlOpts="--netrc -Lk --cookie-jar /tmp/t"
curlOpts="--netrc-file $PATH_FILE_NETRC -Lk --cookie-jar /tmp/t"
baseURLSciHub="https://scihub.copernicus.eu/dhus/odata/v1/Products"
# require:
# - PATH_DIR_DATA_SEN2
# - curlOpts ( includes path_to_netrc)
# - baseURLSciHub

path_to_orig_dir=$(pwd)
finished=false
attemptNo=0
errorousDataNo=0
while [ "$finished" = false ]; do
    finished=true
    attemptNo=$((attemptNo + 1))
    printf "#--------------\n"
    printf "# ${attemptNo}. attempt..\n"
    printf "#--------------\n"
    for s2fname in $PATH_DIR_DATA_SEN2/*/*/*/S2*.zip; do
        printf "checking '$s2fname' ... "
        cd ${s2fname%/*}
        #s2fnameShort=${s2fname##*/}
        s2fnameShort=$(basename $s2fname)
        s2fnameShortBody=${s2fnameShort%.SAFE.zip*}
        tmp=$(du $s2fname)
        filesize=$(echo "$tmp" | cut -f 1)
        if (($filesize < 10)); then
	    echo "directory size <= 10 bytes. Doesn't contain data."
            #echo "file size is small: $filesize"
            filecontent=$(cat $s2fname)
            if [[ $filecontent = *"Request accepted"* ]]; then 
                printf "Was OFFLINE previously -> Re-downloading via Code-DE: $s2fname\n"
                s2url="https://code-de.org/download/${s2fnameShort}"
                echo $s2url | xargs -n1 -P${parallel} $noExec curl $curlOpts -O
                finished=false
            elif [[ $filecontent = *"unavailable"* ]] || [[ $filecontent = *"failed"* ]]; then
                printf "UNAVAILABLE on Code-DO -> Downloading via ESA Sci-Hub: $s2fname\n"
                #curl --netrc -o ${s2fnameShortBody}.xml -LkJO "https://scihub.copernicus.eu/dhus/odata/v1/Products?\$filter=substringof('${s2fnameShortBody}',Name)"
                curl --netrc-file $PATH_FILE_NETRC -o ${s2fnameShortBody}.xml -LkJO "https://scihub.copernicus.eu/dhus/odata/v1/Products?\$filter=substringof('${s2fnameShortBody}',Name)"
                #curl --netrc -o ${s2fnameShortBody}.xml -LkJO "${baseURLSciHub}?\$filter=substringof('${s2fnameShortBody}',Name)"
                tmpstr=$(cat ${s2fnameShortBody}.xml | sed -e 's/^.*<entry><id>'//)
                myurl=${tmpstr%</id>*}
				printf "downloading the following url: ${myurl}\n"
				#curl --netrc -LkJO "${myurl}/\$value"
				curl --netrc-file $PATH_FILE_NETRC -LkJO "${myurl}/\$value"
                rm ${s2fnameShortBody}.xml
                mv ${s2fnameShortBody}.zip ${s2fnameShortBody}.SAFE.zip
            else
                printf "  -> ERROR: There is somethng wrong with this file: $s2fname\n"
                # cat $s2fname
                printf "     .. adding to list of cities whose products require inspection.."
                errorDataList[errorousDataNo]=$s2fname
                errorousDataNo=$(($errorousDataNo + 1))
            fi
        else
		echo "directory size > 10 bytes. Seems OK."
	fi
    done
    if [ "$finished" = false ]; then
        sleep 10
    fi
done
cd $path_to_orig_dir

if [[ $errorousDataNo > 0 ]]; then
    printf "The following files seems to be errorous and require manual inspection:\n"
    for (( i=0; i < ${#errorDataList[@]}; i++)); do
    	printf "  $errorDataList[i]"
    done	
fi

# PATH_DIR_DATA_SEN2="/home/ga39yoz/data/s2SR/LCZ42/sen2"
# noExec=''
# curlOpts='--insecure --netrc-file /home/ga39yoz/data/s2SR/LCZ42/src/.netrc_code-de --location --cookie-jar /tmp/t'
# batchSize=10
# parallel=1
# 
# path_to_ROIs="/home/ga39yoz/data/s2SR/LCZ42/ROIs/ROIs.csv"
# 
# echo
# printf "###############################################\n"
# printf "#  downloading missing data\n"
# printf "###############################################\n"
# dir_orig=$(pwd)
# finished=false
# attemptNo=0
# errorousDataNo=0
# while [ "$finished" = false ]; do
#     finished=true
#     attemptNo=$((attemptNo + 1))
#     printf "#--------------\n# ${attemptNo}. attempt..\n#--------------\n"
#     for s2fname in $PATH_DIR_DATA_SEN2/*/*/*/S2*; do
#         cd ${s2fname%/*}
#         s2fnameShort=${s2fname##*/}
#         s2url="https://code-de.org/download/${s2fnameShort}"
#         tmp=$(du $s2fname)
#         filesize=$(echo "$tmp" | cut -f 1)
#         if (($filesize < 10)); then
#             #echo "file size is small: $filesize"
#             filecontent=$(cat $s2fname)
#             if [[ $filecontent = *"Request accepted"* ]]; then 
#                 printf "  -> Re-downloading this file: $s2fname\n"
#                 echo $s2url | xargs -n1 -P${parallel} $noExec curl $curlOpts -O
#                 finished=false
#             else
#                 printf "  -> ERROR: this file seems unavailable: $s2fname\n"
#                 cat $s2fname
#                 printf "     .. adding to list of cities to be re-processed.."
#                 errorDataTmp=${s2fname%/*}
#                 errorDataTmp=${errorDataTmp%/*}
#                 errorDataTmp=${errorDataTmp%/*}
#                 errorDataTmp=${errorDataTmp##*/}
#                 errorDataList[errorousDataNo]=$errorDataTmp
#                 errorousDataNo=$(($errorousDataNo + 1))
# 
#                 # curl -u claasgr:Eshgham15.05.15 -LkJO "https://scihub.copernicus.eu/dhus/odata/v1/Products('13e66985-7d1f-4a7c-be58-925e7ed7889d')/\$value"
# 
#             fi
#         fi
#     done
#     #sleep 10
# done
# cd $dir_orig
# 
# if [[ $errorousDataNo > 0 ]]; then
#     echo
#     printf "############################################################\n"
#     printf "#  reprocess ROIs with tiles that have become unavailable\n"
#     printf "############################################################\n"
# 
#     mv $path_to_ROIs "$path_to_ROIs.backup"
#     printf "The following ROIs have corresponding unavailable data: \n"
#     for ROIName in "${errorDataList[@]}"; do
#         echo $ROIName
#         tmp=$(grep $ROIName $path_to_ROIs.backup)
#         echo "$tmp" >> $path_to_ROIs
#     done
# 
# fi



