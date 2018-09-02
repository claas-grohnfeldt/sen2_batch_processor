#!/usr/bin/env bash

# Create an anaconda environment for Python 3.6
# named "sen2_batch_processor" without asking for 
# confirmation. Package version takes precedence 
# over channel prior. Lastly, update dependencies.
conda create -n sen2_batch_processor -y python=3.6 \
             --no-channel-priority --update-deps

# Add conda channel conda-forge, which - at the time of
# development - was ahead of the default channels by
# means of gdal version 2.3.1 (which is required by
# the Sentinel-2 processing tools)
conda config --add channels conda-forge
conda install --name sen2_batch_processor -y --file requirements.txt

# activate conda environment
source activate sen2_batch_processor
