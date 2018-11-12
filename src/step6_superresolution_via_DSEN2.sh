#!/bin/bash
# Make sure that commands which fail will cause the shell script to exit immediately
set -e 

# load paths
. configure.sh

PATH_FILE_PROG_DSEN2="$PATH_DIR_DSEN2/testing/s2_tiles_supres.py"

cd $PATH_DIR_DSEN2/testing

for s2fname in $PATH_DIR_DATA_SEN2/*/*/tiles/S2*_MSIL1C_*.zip; do
    echo "s2fname = $s2fname"
    s2dname=$(dirname $s2fname)
    echo "s2dname = $s2dname"
    this_roi_lon_lat=$(cat $s2dname/../../ROI.csv)
    echo "this_rio_lon_lat = $this_roi_lon_lat"
    python3 $PATH_FILE_PROG_DSEN2 $s2fname ${s2fname/.SAFE.zip/_superres.tif} \
        --roi_lon_lat "$this_roi_lon_lat" # --roi_x_y "1000,1000,1200,1200" # 
        # --output_file_format "ENVI"
done

cd -
