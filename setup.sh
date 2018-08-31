#!/usr/bin/env bash

# create an anaconda environment for Python 3.6
conda create -n sen2_batch_processor python=3.6

# activate conda environment
source activate sen2_batch_processor

# # install python packages listed in the file 'requirements.txt'
# while read requirement; do 
#     # note: the parameter "-c conda-forge" can be removed 
#     #       as soon as gdal version >= 2.3.1 becomes
#     #       available in the default anaconda channel
#     #       (check status on https://anaconda.org/anaconda/gdal)
# 	conda install --yes -c conda-forge $requirement
# done < requirements.txt

