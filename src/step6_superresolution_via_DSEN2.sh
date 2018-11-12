#!/bin/bash
# Make sure that commands which fail will cause the shell script to exit immediately
set -e 

# load paths
. configure.sh

PATH_FILE_PROG_DSEN2="$PATH_DIR_DSEN2/testing/s2_tiles_supres.py"

for s2fname in $PATH_DIR_DATA_SEN2/*/*/tiles/S2*_MSIL1C_*.zip; do
    this_roi_lon_lat=$(cat $s2fname/../../ROI.csv)
    python3 $PATH_FILE_PROG_DSEN2 $s2fname ${s2fname/.zip/_superres.tif} \
        --roi_x_y "1000,1000,1200,1200" # --roi_lon_lat "$this_roi_lon_lat" 
        # --output_file_format "ENVI"
done
