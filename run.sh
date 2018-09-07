#!/usr/bin/env bash
#
# File: 
#   run.sh 
# 
# Description: 
#   high-level interface to call various subroutines implemented in this toolbox
# 
function usage {
  echo "Usage:"
  echo "$0 [-d|--download] [-s|--sen2cor] [-p|parallel=1] [-a|--all]"
  echo "  -d, --download    download Sentinel-2 data"
  echo "  -s, --sen2cor     convert L1C to L2A products via sen2cor"
  echo "  -a, --all         process all. Same as --download --sen2cor"
  echo "  -p, --parallel    number of cores used for processing"
  echo "  -i, --info        print information about ROIs, paths and settings"
  exit 1;
}

#defaults
#download=false
#sen2cor=false
#all=false
#info=false
parallel=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d|--download) download=true; shift 1;;
    -u|--sen2cor)  sen2cor=true;  shift 1;;
    -a|--all)      all=true;      shift 1;;
    -p|--parallel) parallel="$2";   shift 2;;
    -i|--info)     info=true;     shift 1;;

    -p=*|--parallel=*) parallel="${1#*=}"; shift 1;;
    *) echo "ERROR: unknown option '$1'"; usage; exit;;
  esac
done

# load paths and preferences
. configure.sh

#gdalinfo --version
# activate conda environment
source activate $NAME_CONDA_ENVIRONMENT
#gdalinfo --version

echo "------------>"
echo $download
echo $sen2cor
echo $all
echo $parallel
echo $info
echo "<------------"



# ------------------------------------------
# sen2cor L1C -> L2A
# ------------------------------------------
# # preparation
# bash $PATH_DIR_MAIN/src/step5_L1C_to_L2A_via_sen2cor.sh
# 
# # parllel processing
# python3 $PATH_DIR_MAIN/src/step5_L1C_to_L2A_via_sen2cor_parallel_wrapper.py



conda deactivate
#gdalinfo --version
