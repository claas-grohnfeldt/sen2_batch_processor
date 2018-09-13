#!/usr/bin/env bash

format_file_out="ENVI"

path_dir_input="/mnt/ssd2/Projects/S2_superresolution/data/sen2_jio/LCZ42_204371_Munich/winter/tiles"

# --------------------
#tile_file_input_list=${path_dir_input}/*.SAFE.zip
tile_file_input_list=${path_dir_input}/*_MSIL1C_*.SAFE/MTD_MSIL1C.xml
#tile_file_input_list=${path_dir_input}/*_MSIL2A_*.SAFE/MTD_MSIL2A.xml
path_ROI="${path_dir_input}/../../ROI.csv"
path_dir_out=${path_dir_input}/tiles_cropped_to_ROI_0
mkdir -p $path_dir_out

echo "path_dir_input = $path_dir_input"
echo "tile_file_input_list = $tile_file_input_list"
echo "path_ROI = $path_ROI"
echo "path_dir_out = $path_dir_out"

for path_file_input in $tile_file_input_list; do
    echo "path_file_input = $path_file_input"
    roi_lon_lat=$(cat $path_ROI)
    echo "roi_lon_lat = $roi_lon_lat"
 	#fname_file_input=$(basename -- "$path_file_input")
    fname_file_input=$(echo $path_file_input | sed 's/.SAFE.*/\.SAFE/' | xargs basename)
 	fname_file_out="${fname_file_input%%.*}_cropped"
 	#roi_lon_lat="4.129657,1.668,79.123,80.598"
 	python crop_sentinel2_data.py \
 	    --output_file_format $format_file_out \
 	    --write_cropped_input_data \
 	    --save_prefix $path_dir_out \
 	    --roi_lon_lat=$roi_lon_lat \
 	    $path_file_input \
 	    $fname_file_out
 	#     # --write_images \
 	#     # --num_threads $num_threads \
 	#     #--list_bands \
 	#     #--list_UTM \
done
# --------------------
