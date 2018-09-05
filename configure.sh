#!/usr/bin/env bash

PATH_DIR_MAIN=$(pwd)
PATH_DIR_TMP="${PATH_DIR_MAIN}/tmp"
PATH_DIR_CODE_DE_TOOLS="${PATH_DIR_MAIN}/src/thirdparties/code-de-tools"
PATH_DIR_DATA="${PATH_DIR_MAIN}/data"
PATH_FILE_NETRC="${PATH_DIR_MAIN}/.netrc"

NAME_CONDA_ENVIRONMENT="sen2_batch_processor"

SOURCE_S2_TILING_GRID="https://sentinel.esa.int/documents/247904/1955685/S2A_OPER_GIP_TILPAR_MPC__20151209T095117_V20150622T000000_21000101T000000_B00.kml"
PATH_FILE_S2_TILING_GRID="$PATH_DIR_DATA/Sentinel2_global_tiling_grid.kml"

SOURCE_SEN2COR="http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run"
PATH_DIR_SEN2COR="${PATH_DIR_MAIN}/src/thirdparties/sen2cor"
