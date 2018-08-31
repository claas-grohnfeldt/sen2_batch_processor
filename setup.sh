#!/usr/bin/env bash

# create an anaconda environment for Python 3.6
conda create -n sen2_batch_processor python=3.6

# activate conda environment
source activate sen2_batch_processor

# install python packages listed in the file 'requirements.txt'
while read requirement; do 
    # note: the parameter "-c conda-forge" can be rem
	conda install --yes -c conda-forge $requirement
done < requirements.txt

