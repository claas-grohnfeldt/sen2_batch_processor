#!/usr/bin/env bash

PATH_DIR_MAIN=$(pwd)

#----------------------
# data
#----------------------
PATH_DIR_DATA="$PATH_DIR_MAIN/data"
PATH_DIR_DATA_SEN2="${PATH_DIR_DATA}/sen2"

#----------------------
# input directory and ROI file
#----------------------
PATH_DIR_INPUT="$PATH_DIR_MAIN/input"
PATH_FILE_ROIs="$PATH_DIR_INPUT/ROIs.csv"

#----------------------
# temporary files
#----------------------
PATH_DIR_TMP="$PATH_DIR_MAIN/tmp"
PATH_LINK_SEN2COR_TO_BE_PROCESSED_LIST="$PATH_DIR_TMP/sen2cor_to_be_processed.txt"

#----------------------
# source code
#----------------------
PATH_DIR_SRC="$PATH_DIR_MAIN/src"
PATH_FILE_python_script_find_best_tiles="$PATH_DIR_SRC/find_best_set_of_unique_tiles.py"

#---- THIRDPARTIES ----
PATH_DIR_SRC_3RDPARTIES="$PATH_DIR_SRC/thirdparties"
# CODE-DE
SOURCE_CODE_DE_TOOLS_GIT="https://github.com/dlr-eoc/code-de-tools.git"
PATH_DIR_CODE_DE_TOOLS="$PATH_DIR_SRC_3RDPARTIES/code-de-tools"
PATH_FILE_CodeDE_query_download="$PATH_DIR_CODE_DE_TOOLS/bin/code-de-query-download.sh"
# Sen2Cor
SOURCE_SEN2COR="http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run"
PATH_DIR_SEN2COR="$PATH_DIR_SRC_3RDPARTIES/sen2cor"
# Deep Sentinel-2
SOURCE_DSEN2="https://github.com/lanha/DSen2/archive/master.zip"
PATH_DIR_DSEN2="$PATH_DIR_SRC_3RDPARTIES/DSen2"

#----------------------
# auxiliary files
#----------------------
PATH_DIR_AUX="$PATH_DIR_MAIN/aux"
SOURCE_S2_TILING_GRID="https://sentinel.esa.int/documents/247904/1955685/S2A_OPER_GIP_TILPAR_MPC__20151209T095117_V20150622T000000_21000101T000000_B00.kml"
PATH_FILE_S2_TILING_GRID="$PATH_DIR_AUX/Sentinel2_global_tiling_grid.kml"
PATH_FILE_Sentinel2_tiling_grid_kml=$PATH_FILE_S2_TILING_GRID

#----------------------
# authentication
#----------------------
PATH_DIR_AUTHENTICATION="$PATH_DIR_MAIN/authentication"
PATH_FILE_NETRC="$PATH_DIR_AUTHENTICATION/.netrc"

#----------------------
# conda environment
#----------------------
NAME_CONDA_ENVIRONMENT="sen2_batch_processor"
