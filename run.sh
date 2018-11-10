#!/usr/bin/env bash
#
# File: 
#   run.sh 
# 
# Description: 
#   high-level interface to call various subroutines implemented in this toolbox
#

script_name=$(basename -- "$0")
echo "-----------------------------------"
echo "executing '$script_name $@'"
echo "-----------------------------------"
function usage {
  echo "Usage:"
  echo "$0 [-d|--download] [-s|--sen2cor] [-p|parallel=1] [-a|--all] [-i|--info]"
  echo "  -d, --download    download Sentinel-2 data"
  echo "  -s, --sen2cor     convert L1C to L2A products via sen2cor"
  echo "  -a, --all         process all. Same as --download --sen2cor"
  echo "  -p, --parallel    number of cores used for processing"
  echo "  -i, --info        print information about ROIs, paths and settings"
  #exit 1;
}

# required (init):
PARALLEL=1

if [ "$#" -eq 0 ]; then
  echo "No program arguments specified."
  usage
  echo "Using default behaviour: --all (equivalent to --download --sen2cor)"
  read -p "Do you wish to proceed? [y]es [n]o (dafault: [n]): " PROCEED
  if [ "$PROCEED" = y ] || [ "$PROCEED" = yes ]; then
    echo "OK. proceeding.."
  else
    echo "No? OK. Abbording now."
    exit 1
  fi
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d|--download) DOWNLOAD=true; shift 1;;
    -u|--sen2cor)  SEN2COR=true;  shift 1;;
    -a|--all)      ALL=true;      shift 1;;
    -p|--parallel) PARALLEL="$2";   shift 2;;
    -i|--info)     INFO=true;     shift 1;;
    -h|--help)     usage; exit;;
    -p=*|--parallel=*) PARALLEL="${1#*=}"; shift 1;;
    *) echo "ERROR: unknown option '$1'"; usage; exit 1; exit;;
  esac
done

# load paths and preferences
. configure.sh

# activate conda environment
source activate $NAME_CONDA_ENVIRONMENT

if [ "$ALL" = true ] || [ "$DOWNLOAD" = true ]; then
    echo "-----------------------------"
    echo " downloading"
    echo "-----------------------------"
	DAYLIGHT_ACQUISITIONS_ONLY=false
	bash $PATH_DIR_SRC/step3_download_via_codede.sh
	echo 
	echo " re-downloading ... "
	bash $PATH_DIR_SRC/step4_reload_files_that_where_offline_previously.sh
	echo "done."
fi

if [ "$ALL" = true ] || [ "$SEN2COR" = true ]; then
    echo "------------------------------------------"
    echo " sen2cor L1C -> L2A"
    echo "------------------------------------------"
	# preparation
	bash $PATH_DIR_SRC/step5_L1C_to_L2A_via_sen2cor.sh
	
	# parallel processing
	PATH_FILE_L2A_PROCESS="${PATH_DIR_SEN2COR}/bin/L2A_Process"
	python3 $PATH_DIR_SRC/step5_L1C_to_L2A_via_sen2cor_parallel_wrapper.py --parallel=$PARALLEL --file_L2A_Process=$PATH_FILE_L2A_PROCESS --file_source_list=$PATH_LINK_SEN2COR_TO_BE_PROCESSED_LIST --remove_L1C_SAFE_folder
fi


conda deactivate
