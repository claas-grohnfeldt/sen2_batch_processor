#!/usr/bin/env bash

format_file_out="ENVI"

PATH_DIR_INPUT="/mnt/ssd2/Projects/S2_superresolution/data/sen2_jio/LCZ42_204371_Munich/winter/tiles"

# --------------------
#TILE_FILE_INPUT_LIST=${PATH_DIR_INPUT}/*.SAFE.zip
TILE_FILE_INPUT_LIST=${PATH_DIR_INPUT}/*_MSIL1C_*.SAFE/MTD_MSIL1C.xml
#TILE_FILE_INPUT_LIST=${PATH_DIR_INPUT}/*_MSIL2A_*.SAFE/MTD_MSIL2A.xml
PATH_ROI="${PATH_DIR_INPUT}/../../ROI.csv"
PATH_DIR_OUT=${PATH_DIR_INPUT}/tiles_cropped_to_ROI_0
mkdir -p $PATH_DIR_OUT

echo "PATH_DIR_INPUT = $PATH_DIR_INPUT"
echo "TILE_FILE_INPUT_LIST = $TILE_FILE_INPUT_LIST"
echo "PATH_ROI = $PATH_ROI"
echo "PATH_DIR_OUT = $PATH_DIR_OUT"

for PATH_FILE_INPUT in $TILE_FILE_INPUT_LIST; do
    echo "PATH_FILE_INPUT = $PATH_FILE_INPUT"
    ROI_LON_LAT=$(cat $PATH_ROI)
    echo "ROI_LON_LAT = $ROI_LON_LAT"
 	#fname_file_input=$(basename -- "$PATH_FILE_INPUT")
    fname_file_input=$(echo $PATH_FILE_INPUT | sed 's/.SAFE.*/\.SAFE/' | xargs basename)
 	FNAME_FILE_OUT="${fname_file_input%%.*}_cropped"
 	#ROI_LON_LAT="4.129657,1.668,79.123,80.598"
 	python crop_sentinel2_data.py \
 	    --output_file_format $format_file_out \
 	    --write_cropped_input_data \
 	    --save_prefix $PATH_DIR_OUT \
 	    --roi_lon_lat=$ROI_LON_LAT \
 	    $PATH_FILE_INPUT \
 	    $FNAME_FILE_OUT
 	#     # --write_images \
 	#     # --num_threads $num_threads \
 	#     #--list_bands \
 	#     #--list_UTM \
done
# kop
# kop
# kop
# kop
# kop
# kop
# kop
# kop
# kop
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
# jio jio jio jio jio jio jio jio jio jio jio 
for j in {1..9}; do
    echo "do stuff"
done
# --------------------
