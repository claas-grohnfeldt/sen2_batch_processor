#!/usr/bin/env bash
#
# File: 
#   run.sh 
# 
# Description: 
#   high-level interface to call various subroutines implemented in this toolbox
#
python3 testest.py

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

#defaults
#download=false
#sen2cor=false
#all=false
#info=false
parallel=1

if [ "$#" -eq 0 ]; then
  echo "No program arguments specified."
  usage
  echo "Using default behaviour: --all (equivalent to --download --sen2cor)"
  read -p "Do you wish to proceed? [y]es [n]o (dafault: [n]): " proceed
  if [ "$proceed" = y ] || [ "$proceed" = yes ]; then
    echo "OK. proceeding.."
  else
    echo "No? OK. Abbording now."
    exit 1
  fi
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d|--download) download=true; shift 1;;
    -u|--sen2cor)  sen2cor=true;  shift 1;;
    -a|--all)      all=true;      shift 1;;
    -p|--parallel) parallel="$2";   shift 2;;
    -i|--info)     info=true;     shift 1;;
    -h|--help)     usage; exit;;
    -p=*|--parallel=*) parallel="${1#*=}"; shift 1;;
    *) echo "ERROR: unknown option '$1'"; usage; exit 1; exit;;
  esac
done

# load paths and preferences
. configure.sh

#gdalinfo --version
# activate conda environment
source activate $NAME_CONDA_ENVIRONMENT
#gdalinfo --version

# echo "------------>"
# echo $download
# echo $sen2cor
# echo $all
# echo $parallel
# echo $info
# echo "<------------"

echo "-----------------------------"
echo " downloading"
echo "-----------------------------"
if [ "$all" = true ] || [ "$download" = true ]; then
	daylight_acquisitions_only=false
	bash $PATH_DIR_SRC/step3_download_via_codede.sh
	echo 
	echo " re-downloading ... "
	bash $PATH_DIR_SRC/step4_reload_files_that_where_offline_previously.sh
	echo "done."
fi

echo "------------------------------------------"
echo " sen2cor L1C -> L2A"
echo "------------------------------------------"
if [ "$all" = true ] || [ "$sen2cor" = true ]; then
	# preparation
	bash $PATH_DIR_SRC/step5_L1C_to_L2A_via_sen2cor.sh
	
	# parllel processing
	python3 $PATH_DIR_SRC/step5_L1C_to_L2A_via_sen2cor_parallel_wrapper.py
fi


conda deactivate
#gdalinfo --version
