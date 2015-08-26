#! /bin/bash

# Install the OpenSARKit interactive scripts

echo -e "Welcome to the OpenSARKit"
echo -e "Make sure you have the introduction manual by your side (http://fao.org/OpenSARKit.pdf)"

#-----------------------------------
# 1 Installation folder
#-----------------------------------

# ask for installation folder
read -r -p "In which folder you want your OpenSARKit to be installed? (/absolute/path/to/folder): " OPENSARKIT

# assure folder is right, otherwise exit
read -r -p "OpenSARKit will be installed into ${OPENSARKIT}? [y/N]: " response
case $response1 in
    [yY][eE][sS]|[yY])

	# copy files into Installation folder
	PWD=`pwd`
	mkdir ${OPENSARKIT}
	cp ${PWD}/* ${OPENSARKIT}

	# Write source file (later used in .bashrc)
	echo "#! /bin/bash" > ${OPENSARKIT/}OpenSARKit_source.bash
	echo "" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "# Support script to source the original programs" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "# Folder of OpenSARKit scripts and workflows" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "export OPENSARKIT=${OPENSARKIT}" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "# source OSK workflows/graphs" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "export NEST_GRAPHS=${OPENSARKIT}/graphs/NEST" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "export S1TBX_GRAPHS=${OPENSARKIT}/graphs/S1TBX" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "source OSK scripts" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "export NEST_BIN=${OPENSARKIT}/bins/NEST" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "export S1TBX_BIN=${OPENSARKIT}/bins/S1TBX" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "Aliases" >> ${OPENSARKIT/}OpenSARKit_source.bash
	cat ${OPENSARKIT}/.aliases >> ${OPENSARKIT/}OpenSARKit_source.bash
	;;
*)
	echo "installation failed"
	exit 1
esac

#-----------------------------------
# 2 Check for 3rd party software
#-----------------------------------

echo "The files of OpenSARKit are now in place."
echo "We will check for 3rd party Software on your Computer."
read -p "Are you ready? Then just hit [ENTER]!"

# 2a check for S1TBX installation
read -r -p "Have you already installed the Sentinel 1 Toolbox? [y/N]: " response1
case $response1 in
    [yY][eE][sS]|[yY])
	
	read -r -p "Please type the full installation path (i.e. the folder where your gpt.sh is located): \n" 	S1TBX		

	# write paths into source file
	echo "" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "Source S1 Toolbox command line executable" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "export S1TBX_EXE=${S1TBX}/gpt.sh" >> ${OPENSARKIT/}OpenSARKit_source.bash
	;;
*)

	read -r -p "Do you want to install it now? [y/N] " response2
	case $response2 in
    		[yY][eE][sS]|[yY])

		if [[ `uname -p` == x86_64 ]]; then 
			wget http://sentinel1.s3.amazonaws.com/1.0/s1tbx_1.1.1_Linux64_installer.sh 
		else 
			wget http://sentinel1.s3.amazonaws.com/1.0/s1tbx_1.1.1_Linux32_installer.sh
		fi
		;;
		*) 
		
		echo "You will run OpenSARToolkit without Sentinel 1 Toolbox"

	esac
esac


# 2b check for NEST installation
read -r -p "Have you already installed the NEST (Next ESA SAR Toolbox? [y/N]: " response2
case $response2 in
    [yY][eE][sS]|[yY])
	
	read -r -p "Please type the full installation path of NEST (i.e. the folder where your gpt.sh is located): \n" 	NEST		

	# write paths into source file
	echo "" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "Source S1 Toolbox command line executable" >> ${OPENSARKIT/}OpenSARKit_source.bash
	echo "export NEST_EXE=${NEST}/gpt.sh" >> ${OPENSARKIT/}OpenSARKit_source.bash
	;;
*)

	echo "If you want to install it, go to https://earth.esa.int/web/nest/downloads , register, download and install " 
	echo "" 
	echo "!!!Attention!!! MAKE SURE YOU GONNA A GLOBAL ENVIRONMENTAL VARIABLE NEST_EXE TO ~./bashrc !!!Attention!!! "
	echo "e.g. type in the terminal: echo \"export NEST_EXE=/home/NEST/gpt.sh >> ~/.bashrc\""
	read -p "Hit [ENTER] to continue" 
esac

read -r -p "Do you want to add all paths to you local ./bashrc " response3
case $response3 in
    [yY][eE][sS]|[yY])


    	echo "" >> ~/.bashrc
	echo "# source OpenSARKit" >> ~/.bashrc
    	echo "source ${OPENSARKIT/}OpenSARKit_source.bash" >> ~/.bashrc
    	;;
*)
	echo "Ok, but don't blame me if you forget to source the commands"
	read -p "Hit [ENTER] to finish the Installation"
case
