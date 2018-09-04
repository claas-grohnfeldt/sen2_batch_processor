#!/usr/bin/env bash

#. settings.cfg
. configure.sh

# PATH_TARGET_DIR_MAIN=$(pwd)
# PATH_DIR_TMP="${PATH_TARGET_DIR_MAIN}/tmp"
# PATH_TARGET_DIR_SEN2COR="${PATH_TARGET_DIR_MAIN}/src/thirdparties/sen2cor"
# PATH_TARGET_DIR_CODE_DE_TOOLS="${PATH_TARGET_DIR_MAIN}/src/thirdparties/code-de-tools"
# PATH_FILE_NETRC=${HOME}/.netrc

mkdir -p $PATH_DIR_TMP
mkdir -p $PATH_TARGET_DIR_SEN2COR

echo
echo "#####################################################################################"
echo "# This script is to install the 'sen2_batch_processor' toolbox and its dependencies."
echo "# Please follow these instructions very carefully."
echo "#####################################################################################"

# new requirement: perl TODO

echo
echo "  This toolbox requires you to possess valid user credentials on both"
echo "  ----->  'https://scihub.copernicus.eu/dhus' (machine: scihub.copernicus.eu) <------"
echo "  and"
echo "  ---------------->  'http://code-de.org (machine sso.eoc.dlr.de)'  <----------------"
read -p "> Do you have a valid user account for each of these websites right now (Y/N) [N]?: " in_possession_of_user_accounts
if [[ $in_possession_of_user_accounts == [yY] || $in_possession_of_user_accounts == [yY][eE][sS] ]]; then
	echo "  Excellent!"
else
	echo
	echo "  Please sign up on the respective website(s) and run this installer"
	echo "  again once you possess valid credentials."
	echo
	echo "  Abbording now."
	exit
fi

echo
echo "  +-------------------------------------"
echo "  | Setting up a netrc file for login"
echo "  +-------------------------------------"
if [ -f ${PATH_FILE_NETRC} ]; then
	echo "  File '${PATH_FILE_NETRC}' already exists. That's OK. We'll update it here if necessary."
else
	echo "  File '${PATH_FILE_NETRC}' (.netrc file)"
	echo "  does not exist. That's OK. It will be created and filled with login information for"
	echo "  'https://scihub.copernicus.eu/dhus' and 'http://code-de.org' in the following steps."
fi

for MACHINE in "scihub.copernicus.eu" "sso.eoc.dlr.de"; do
	if [ -f ${PATH_FILE_NETRC} ] && ( grep -q "machine ${MACHINE}" ${PATH_FILE_NETRC} ); then
		echo
		echo "  There already exists an entry for the machine '${MACHINE}'."
		usrnm=$(grep -2 "machine ${MACHINE}" ${PATH_FILE_NETRC} | grep login | sed 's/^.*login //')
		echo
		echo "> Are those user account credentials (username '$usrnm') valid at the moment?"
		read -p "  (if you are not sure, better examine the ${PATH_FILE_NETRC} file) (Y/N) [N]: " creditials_valid
		if [[ $creditials_valid == [yY] || $creditials_valid == [yY][eE][sS] ]]; then
			echo "  Excellent!"
		else
			echo "  Alright. Let's update your credentials now."
			echo
			read -p "> Please enter your USER NAME for ${MACHINE}: " USRNAME_TMP
			printf "> Please enter your USER PASSWORD for ${MACHINE}: "
			read -s PWD_TMP
			echo
			printf "> Please re-enter your USER PASSWORD: "
			read -s PWD_TMP_validate
			echo
			if ! [ "$PWD_TMP" == "$PWD_TMP_validate" ]; then
				echo
				echo "  Error: Passwords don't match."
				echo
				echo "  Abbording now."
				exit
			fi
			perl -i.original -0400 -pe "s/machine ${MACHINE}(.*?)\n(.*?)login(.*?)\n(.*?)password(.*?)\n/machine ${MACHINE}\n    login ${USRNAME_TMP}\n    password ${PWD_TMP}\n/igs" ${PATH_FILE_NETRC}
			echo "  Successfully updated user accout credentials for machine '${MACHINE}' in '${PATH_FILE_NETRC}'."
			unset PWD_TMP
			unset PWD_TMP_validate
		fi
	else
		echo
		echo "  No user account credentials for machine ${MACHINE}' found "
		echo "  in file '${PATH_FILE_NETRC}'."
		echo "  Let's enter those credentials now."
		echo
		read -p "> Please enter your USER NAME for ${MACHINE}: " USRNAME_TMP
		printf "> Please enter your USER PASSWORD for ${MACHINE}: "
		read -s PWD_TMP
		echo
		printf "> Please re-enter your USER PASSWORD: "
		read -s PWD_TMP_validate
		echo
		if ! [ "$PWD_TMP" == "$PWD_TMP_validate" ]; then
			echo
			echo "  Error: Passwords don't match."
			echo
			echo "  Abbording now."
			exit
		fi
		echo >> ${PATH_FILE_NETRC}
		echo "machine ${MACHINE}" >> ${PATH_FILE_NETRC}
		echo "    login ${USRNAME_TMP}" >> ${PATH_FILE_NETRC}
		echo "    password ${PWD_TMP}" >> ${PATH_FILE_NETRC}
	fi
done
chmod 400 ${PATH_FILE_NETRC}

echo
echo "Great. netrc setup completed."

echo
echo "  +-------------------------------------"
echo "  | Setting up sen2cor"
echo "  +-------------------------------------"
INSTALL_SEN2COR=true
# Check if there exists a local installation of sen2cor in this project directory. 
if [ -f "${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process" ]; then
	echo "  File '${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process' already exists.";
	if [ "$(bash ${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process -h | grep 'Sentinel-2 Level 2A Processor')" ] ; then 
		echo "  Program seems to be OK.";
		echo
		read -p "> Would you like to use this existing installation? (Y/N) [Y]: " USE_EXISTING_SEN2COR
		if ! [[ $USE_EXISTING_SEN2COR == [nN] || $USE_EXISTING_SEN2COR == [nN][oO] ]]; then
			INSTALL_SEN2COR=false
			PATH_TARGET_FILE_L2A_Process=${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process
		fi
	else
		echo "  Warning: Something is wrong with that existing program (L2A_Process)."
	fi
fi
if $INSTALL_SEN2COR; then
	echo
	echo "> Do you have recent version of sen2cor (version >= 2.5.5) installed on your"
	echo "  machine which you would like to use in this project? (If not, sen2cor will"
	printf "  be downloaded and installed locally in this project folder? (Y/N) [N]: "
	read sen2cor_installed 
	
	if [[ $sen2cor_installed == [yY] || $sen2cor_installed == [yY][eE][sS] ]]; then
		echo "> Please enter the full path of the file 'L2A_Process' (by default to be found"
		read -p "  <path_to_sen2cor_dir>/bin/L2A_Process): " PATH_TARGET_FILE_L2A_Process
		if [ -f $PATH_TARGET_FILE_L2A_Process ] && [ "$(bash $PATH_TARGET_FILE_L2A_Process -h | grep 'Sentinel-2 Level 2A Processor')" ]; then
			echo "  Path and program (L2A_Process) seem to be OK."
			echo "  Creating symbolic link to the following local project directory:"
			echo "  ${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process"
			mkdir -p ${PATH_TARGET_DIR_SEN2COR}/bin
			ln -s $PATH_TARGET_FILE_L2A_Process ${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process
			echo "  Succeeded."
			INSTALL_SEN2COR=false
		else
			echo "  Warning: There is something wrong with this path or the program (L2A_Process) itself.'"
			echo
		fi
	else
		echo "  Alright. Let's download and install it."
		echo 
	fi
fi
if $INSTALL_SEN2COR; then
	if [ -d ${PATH_TARGET_DIR_SEN2COR} ] && ! [ -z "$(ls -A ${PATH_TARGET_DIR_SEN2COR})" ]; then
		echo "  ! Warning: The default installation directory "
		echo "  ! ${PATH_TARGET_DIR_SEN2COR}/"
		echo "  ! is not empty. The content of that directory is about to be OVERWRITTEN! "
		echo
		read -p "> Would you like to proceed with this? (Y/N) [N]: " PROCEED
		if ! [[ $PROCEED == [yY] || $PROCEED == [yY][eE][sS] ]]; then
			echo
			echo "  Save choice. Abbording now."
			echo
			exit
		else
			echo "  Alright then. Let's do this."
		fi
	fi
	echo
	echo "  Downloading and installing sen2cor now."
	echo
	echo "===>"
	#SOURCE_SEN2COR="http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run"
	#wget 'http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run' -P $PATH_DIR_TMP
	wget "$SOURCE_SEN2COR" -P $PATH_DIR_TMP
	#bash "${PATH_DIR_TMP}/Sen2Cor-02.05.05-Linux64.run" --target "${PATH_TARGET_DIR_SEN2COR}"
	bash "${PATH_DIR_TMP}/$(basename $SOURCE_SEN2COR)" --target "${PATH_TARGET_DIR_SEN2COR}"
	PATH_TARGET_FILE_L2A_Process="${PATH_TARGET_DIR_SEN2COR}/bin/L2A_Process"
	echo "<=== DONE"
	echo
	echo '  Note:'
	echo '  Sen2Cor configuration options and software documentation are available here:'
	echo '  http://step.esa.int/thirdparties/sen2cor/2.5.5/docs/S2-PDGS-MPC-L2A-SUM-V2.5.5_V2.pdf'
fi
echo
echo "  Great. Sen2Cor is good to go."
# TODO: PATH_TARGET_FILE_L2A_Process Needed? If so, make variable available for later use (export?)

echo
echo "  +-------------------------------------"
echo "  | Setting up code-de-tools"
echo "  +-------------------------------------"
INSTALL_CODE_DE_TOOLS=true
# Check if code-de-tools already exist in project directory
if [ -f "${PATH_TARGET_DIR_CODE_DE_TOOLS}/bin/code-de-query-download.sh" ]; then
	echo "  File '${PATH_TARGET_DIR_CODE_DE_TOOLS}/bin/code-de-query-download.sh' already exists.";
	if [ "$(bash ${PATH_TARGET_DIR_CODE_DE_TOOLS}/bin/code-de-query-download.sh | grep 'USAGE:')" ] ; then 
		echo "  Program seems to be OK.";
		echo
		read -p "> Would you like to use this existing installation? (Y/N) [Y]: " USE_EXISTING_CODE_DE_TOOLS
		if ! [[ $USE_EXISTING_CODE_DE_TOOLS == [nN] || $USE_EXISTING_CODE_DE_TOOLS == [nN][oO] ]]; then
			INSTALL_CODE_DE_TOOLS=false
			PATH_TARGET_FILE_CODE_DE_TOOLS_DOWNLOAD=${PATH_TARGET_DIR_CODE_DE_TOOLS}/bin/code-de-query-download.sh
		fi
	else
		echo "  Warning: Something is wrong with that existing program (code-de-query-download.sh)."
	fi
fi
if $INSTALL_CODE_DE_TOOLS; then
	echo
	echo "> Do you have recent version of code-de-tools installed on your machine that "
	echo "  you would like to use in this project? (If not, code-de-tools will be down-"
	printf "  loaded and installed locally in this project folder? (Y/N) [N]: "
	read code_de_tools_installed 
	echo
	
	if [[ $code_de_tools_installed == [yY] || $code_de_tools_installed == [yY][eE][sS] ]]; then
		echo "> Please enter the full path of the file 'code-de-query-download.sh' (by"
		echo "  default to be found <path_to_code_de_tools_dir>/bin/code-de-query-download.sh):"
		printf "  "
		read  PATH_TARGET_FILE_CODE_DE_TOOLS_DOWNLOAD
		echo
		if [ -f $PATH_TARGET_FILE_CODE_DE_TOOLS_DOWNLOAD ] && [ "$(bash $PATH_TARGET_FILE_CODE_DE_TOOLS_DOWNLOAD -h | grep 'USAGE:')" ]; then
			echo "  Path and program (code-de-query-download.sh) seem to be OK."
			echo "  Creating symbolic link to the following local project directory:"
			echo "  ${PATH_TARGET_DIR_CODE_DE_TOOLS}/bin/code-de-query-download.sh"
			mkdir -p "${PATH_TARGET_DIR_CODE_DE_TOOLS}/bin"
			ln -s $PATH_TARGET_FILE_CODE_DE_TOOLS_DOWNLOAD "${PATH_TARGET_DIR_CODE_DE_TOOLS}/bin/code-de-query-download.sh"
			echo "  Succeeded."
			INSTALL_CODE_DE_TOOLS=false
		else
			echo "  Warning: There is something wrong with this path or the program (code-de-query-download.sh) itself.'"
			echo
		fi
	else
		echo 
		echo "  Alright. Let's download and install it."
	fi
fi
if $INSTALL_CODE_DE_TOOLS; then
	if [ -d ${PATH_TARGET_DIR_CODE_DE_TOOLS} ] && ! [ -z "$(ls -A ${PATH_TARGET_DIR_CODE_DE_TOOLS})" ]; then
		echo "  ! Warning: The default installation directory "
		echo "  ! ${PATH_TARGET_DIR_CODE_DE_TOOLS}/"
		echo "  ! is not empty. The content of that directory is about to be DELETED for a clean installation. "
		echo
		read -p "> Would you like to proceed with this? (Y/N) [N]: " PROCEED
		if ! [[ $PROCEED == [yY] || $PROCEED == [yY][eE][sS] ]]; then
			echo
			echo "  Save choice. Abbording now."
			echo
			exit
		else
			echo "  Alright then. Let's do this."
			echo "  Removing the directory '${PATH_TARGET_DIR_CODE_DE_TOOLS}/' .."
			rm -rf "${PATH_TARGET_DIR_CODE_DE_TOOLS}"
			echo "  done."
		fi
	fi
	echo
	echo "  Downloading and installing 'code_de_tools' now."
	echo
	echo "===>"
	git clone https://github.com/dlr-eoc/code-de-tools.git $PATH_TARGET_DIR_CODE_DE_TOOLS
	echo "<=== DONE"
	
fi
echo
echo "  Great. Code-DE-Tools is good to go."

echo
echo "  +-------------------------------------"
echo "  | Setting up SuperRes"
echo "  +-------------------------------------"
# # download superres code
# # TODO

echo
echo "  +-------------------------------------"
echo "  | Download the Sentinel-2 tiling grid"
echo "  +-------------------------------------"
# # download superres code
# # TODO
PATH_DIR_S2_TILING_GRID=${PATH_FILE_S2_TILING_GRID%*$(basename $PATH_FILE_S2_TILING_GRID)}
mkdir -p $PATH_DIR_S2_TILING_GRID
wget "$SOURCE_S2_TILING_GRID" -P $PATH_DIR_S2_TILING_GRID
mv "$PATH_DIR_S2_TILING_GRID/$(basename $SOURCE_S2_TILING_GRID)" "$PATH_FILE_S2_TILING_GRID"

echo
echo "> +-------------------------------------"
echo "  | Setting up a conda environment and"
echo "  | installing required python packages"
echo "  | in that environment."
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



rm -r $PATH_DIR_TMP

# activate conda environment
#source activate $NAME_CONDA_ENVIRONMENT


echo
echo "  Installation completed successfully."
echo 
echo "  Congratilations! The hard part is over! "

echo "  Enjoy using the Sentinel-2 batch download/processing toolbox."
echo
