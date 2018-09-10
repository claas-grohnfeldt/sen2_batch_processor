#!/usr/bin/env bash

PATH_DIR_MAIN=$(pwd)
PATH_DIR_TMP="${PATH_DIR_MAIN}/tmp"
PATH_DIR_SRC="$PATH_DIR_MAIN/src"

PATH_DIR_CODE_DE_TOOLS="$PATH_DIR_SRC/thirdparties/code-de-tools"

#PATH_DIR_DATA="$PATH_DIR_MAIN/data"
PATH_DIR_DATA="/datastore/exchange/grohnfeldt/sen2_batch_processor_data"
path_to_csv_file_ROIs="$PATH_DIR_MAIN/input/ROIs.csv"

SOURCE_S2_TILING_GRID="https://sentinel.esa.int/documents/247904/1955685/S2A_OPER_GIP_TILPAR_MPC__20151209T095117_V20150622T000000_21000101T000000_B00.kml"
PATH_FILE_S2_TILING_GRID="$PATH_DIR_DATA/Sentinel2_global_tiling_grid.kml"
path_to_Sentinel2_tiling_grid_kml_file=$PATH_FILE_S2_TILING_GRID # "${path_to_base_dir}/aux/S2A_OPER_GIP_TILPAR_MPC__20151209T095117_V20150622T000000_21000101T000000_B00.kml"

PATH_FILE_NETRC="$PATH_DIR_MAIN/.netrc"

NAME_CONDA_ENVIRONMENT="sen2_batch_processor"


SOURCE_SEN2COR="http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run"
PATH_DIR_SEN2COR="$PATH_DIR_SRC/thirdparties/sen2cor"

#--------------------------------------
# copied from src/step3_download_via_codede.sh:
path_to_base_dir=$PATH_DIR_MAIN
path_to_src=$PATH_DIR_SRC
path_to_CodeDE_query_download_script="$PATH_DIR_CODE_DE_TOOLS/bin/code-de-query-download.sh"
#path_to_csv_file_ROIs="${path_to_base_dir}/data/ROIs.csv"
path_to_python_script_to_find_best_set_of_tiles="$PATH_DIR_SRC/find_best_set_of_unique_tiles.py"
path_to_target_dir_base="$PATH_DIR_DATA/sen2"

