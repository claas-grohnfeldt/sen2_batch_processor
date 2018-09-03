#!/usr/bin/env bash

PATH_TARGET_DIR_MAIN=$(pwd)
PATH_DIR_TMP="${PATH_TARGET_DIR_MAIN}/tmp"
PATH_TARGET_DIR_SEN2COR="${PATH_TARGET_DIR_MAIN}/src/thirdparties/sen2cor"

mkdir -p $PATH_DIR_TMP
mkdir -p $PATH_TARGET_DIR_SEN2COR

#####################################
# Introduction
#####################################
echo
echo "#####################################################################################"
echo "# This script is to install the 'sen2_batch_processor' toolbox and its dependencies."
echo "# Please follow these instructions very carefully."
echo "#####################################################################################"


# new requirement: perl TODO

echo
echo "> This toolbox requires you to possess valid user credentials on both"
echo "  ----->  'https://scihub.copernicus.eu/dhus' (machine: scihub.copernicus.eu) <------"
echo "  and"
echo "  ---------------->  'http://code-de.org (machine sso.eoc.dlr.de)'  <----------------"
read -p "  Do you have a valid user account for each of these websites right now (Y/N) [N]?: " in_possession_of_user_accounts
if [[ $in_possession_of_user_accounts == [yY] || $in_possession_of_user_accounts == [yY][eE][sS] ]]; then
	echo "  Excellent!"
else
	echo
	echo "> Please sign up on the respective website(s) and run this installer"
	echo "  again once you possess valid credentials."
	echo
	echo "  Abbording now."
	exit
fi

#####################################
# .netrc
#####################################
echo
echo "> +-------------------------------------"
echo "  | Setting up a netrc file for login"
echo "  +-------------------------------------"
if [ -f ${HOME}/.netrc ]; then
	echo "> File '${HOME}/.netrc' already exists. That's OK. We'll update it here if necessary."
else
	echo "> No .netrc file was found in your home directore (${HOME}/.netrc). That's OK."
	echo "  It will be created and filled with login information for"
	echo "  'https://scihub.copernicus.eu/dhus' and 'http://code-de.org' in the following steps."
fi

for MACHINE in "scihub.copernicus.eu" "sso.eoc.dlr.de"; do
	if ( grep -q "machine ${MACHINE}" ${HOME}/.netrc ); then
		echo
		echo "> There already exists an entry for the machine '${MACHINE}'."
		usrnm=$(grep -2 "machine ${MACHINE}" ${HOME}/.netrc | grep login | sed 's/^.*login //')
		echo "  Are those user account credentials (username '$usrnm') valid at the moment?"
		read -p "  (if you are not sure, better examine the ${HOME}/.netrc file) (Y/N) [N]: " creditials_valid
		if [[ $creditials_valid == [yY] || $creditials_valid == [yY][eE][sS] ]]; then
			echo "  Excellent!"
		else
			echo "> Alright. Let's update your credentials now."
			read -p "> Please enter your USER NAME for ${MACHINE}: " USRNAME_TMP
			printf "> Please enter your USER PASSWORD for ${MACHINE}: "
			read -s PWD_TMP
			echo
			printf "> Please re-enter your USER PASSWORD: "
			read -s PWD_TMP_validate
			echo
			if ! [ "$PWD_TMP" == "$PWD_TMP_validate" ]; then
				echo
				echo "> Error: Passwords don't match."
				echo
				echo "  Abbording now."
				exit
			fi
			perl -i.original -0400 -pe "s/machine ${MACHINE}(.*?)\n(.*?)login(.*?)\n(.*?)password(.*?)\n/machine ${MACHINE}\n    login ${USRNAME_TMP}\n    password ${PWD_TMP}\n/igs" ${HOME}/.netrc
			echo "> Successfully updated user accout credentials for machine '${MACHINE}' in '${HOME}/.netrc'."
			unset PWD_TMP
			unset PWD_TMP_validate
		fi
	else
		echo
		echo "> No user account credentials for machine ${MACHINE}' found "
		echo "  in file '${HOME}/.netrc'."
		echo "  Let's enter those credentials now."
		read -p "> Please enter your USER NAME for ${MACHINE}: " USRNAME_TMP
		printf "> Please enter your USER PASSWORD for ${MACHINE}: "
		read -s PWD_TMP
		echo
		printf "> Please re-enter your USER PASSWORD: "
		read -s PWD_TMP_validate
		echo
		if ! [ "$PWD_TMP" == "$PWD_TMP_validate" ]; then
			echo
			echo "> Error: Passwords don't match."
			echo
			echo "  Abbording now."
			exit
		fi
		echo >> ${HOME}/.netrc
		echo "machine ${MACHINE}" >> ${HOME}/.netrc
		echo "    login ${USRNAME_TMP}" >> ${HOME}/.netrc
		echo "    password ${PWD_TMP}" >> ${HOME}/.netrc
	fi
done
chmod 400 ${HOME}/.netrc

echo
echo "> +-------------------------------------"
echo "  | Setting up conda environment and"
echo "  | installing required python packages"
echo "  +-------------------------------------"
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



echo
echo "> +-------------------------------------"
echo "  | Setting up sen2cor"
echo "  +-------------------------------------"
read -p "> Do you have sen2cor (version >= 2.5.5) already installed and would like to the working directory instead of downloading and installing it? (Y/N) [N]: " sen2cor_installed 
if [[ $sen2cor_installed == [yY] || $sen2cor_installed == [yY][eE][sS] ]]; then
	read -p "> Please enter the full path of the file 'L2A_Process' (by default to be found in <path_to_sen2cor_dir>/bin/L2A_Process)" PATH_TARGET_FILE_L2A_Process
	if [ -f PATH_TARGET_FILE_L2A_Process ] && [[ ${PATH_TARGET_FILE_L2A_Process} = *"/L2A_Process" ]]; then
		echo "  path OK."
		export PATH_TARGET_FILE_L2A_Process=${PATH_TARGET_FILE_L2A_Process}
	else
		echo "> Warning: path should end with '/L2A_Process'"
		echo
		echo "> Downloading and installing sen2cor .."
		wget 'http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run' -P $PATH_DIR_TMP
		bash "${PATH_DIR_TMP}/Sen2Cor-02.05.05-Linux64.run" --target "${PATH_TARGET_DIR_SEN2COR}"
		export PATH_TARGET_FILE_L2A_Process="${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process"
	fi
else
	echo "  Alright. Let's download and install it now."
	echo 
	echo "> Downloading and installing sen2cor .."
	wget 'http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run' -P $PATH_DIR_TMP
	bash "${PATH_DIR_TMP}/Sen2Cor-02.05.05-Linux64.run" --target "${PATH_TARGET_DIR_SEN2COR}"
	export PATH_TARGET_FILE_L2A_Process="${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process"
fi

echo
echo 'Note:'
echo 'Sen2Cor configuration options and software documentation are available here:'
echo 'http://step.esa.int/thirdparties/sen2cor/2.5.5/docs/S2-PDGS-MPC-L2A-SUM-V2.5.5_V2.pdf'
echo

# download code-de-tools
# TODO

# download superres code
# TODO


#rm -r $PATH_DIR_TMP

# activate conda environment
source activate sen2_batch_processor
