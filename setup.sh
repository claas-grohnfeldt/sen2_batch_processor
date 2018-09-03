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

# TODO
# outsource to configuration file:
path_dir_main=$(pwd)

# download and install sen2cor
path_sen2cor=""

# TODO
echo 'Do you have sen2cor (version >= 2.5.5) already installed?'

read -p "Do you have sen2cor (version >= 2.5.5) already installed? (Y/N) [N]: " sen2cor_installed 
if [[ $sen2cor_installed == [yY] || $sen2cor_installed == [yY][eE][sS] ]]; then
	Please enter the full path to the file L2A_Process
else
	mkdir -p src/thirdparty_tools/sen2cor
fi

cd src/thirdparty_tools/sen2cor
wget 'http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run'
bash 'sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run'


echo
echo 'Note:'
echo 'Sen2Cor configuration options and sowtware documentation are available here:'
echo 'http://step.esa.int/thirdparties/sen2cor/2.5.5/docs/S2-PDGS-MPC-L2A-SUM-V2.5.5_V2.pdf'
echo

# download code-de-tools
# TODO

# download superres code
# TODO


# activate conda environment
source activate sen2_batch_processor
