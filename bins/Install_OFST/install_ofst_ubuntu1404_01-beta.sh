#! /bin/bash

OSK_VERSION="0.1-beta"

if [ "$#" == "0" ];then

	echo -e ""
	echo -e "----------------------------------"
	echo -e " Open Foris SAR Toolkit, version ${OSK_VERSION}"
	echo -e " Install script"
	echo -e "----------------------------------"
	echo -e ""
	export OSK_HOME=/usr/local/lib/osk

elif [ "$#" == "1" ];then

	echo -e ""
	echo -e "----------------------------------"
	echo -e " Open Foris SAR Toolkit, version ${OSK_VERSION}"
	echo -e " Install script"
	echo -e "----------------------------------"
	echo -e ""
	export OSK_HOME=$1


elif [ "$#" == "2" ];then

	echo -e ""
	echo -e "----------------------------------"
	echo -e " Open Foris SAR Toolkit, version ${OSK_VERSION}"
	echo -e " Install script"
	echo -e "----------------------------------"
	echo -e ""
	export OSK_HOME=$1

else 

	echo -e ""
	echo -e "----------------------------------"
	echo -e " Open Foris SAR Toolkit, version ${OSK_VERSION}"
	echo -e " Install script"
	echo -e "----------------------------------"
	echo -e ""
	echo -e " syntax: install_osk <installation_folder>"
	echo -e ""
	echo -e " description of input parameters:"
	echo -e " installation_folder		(output) path to installation folder of OSK"
	exit 1
fi


spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|\-/'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Licenses
echo " The MIT License (MIT)"
echo " Copyright (c) 2016 Andreas Vollrath"
echo " "
echo " Permission is hereby granted, free of charge, to any person obtaining a copy"
echo " of this software and associated documentation files (the "Software"), to deal "
echo " in the Software without restriction, including without limitation the rights "
echo " to use, copy, modify, merge, publish, distribute, sublicense, and/or sell "
echo " copies of the Software, and to permit persons to whom the Software is furnished"
echo " to do so, subject to the following conditions:"
echo " "
echo " The above copyright notice and this permission notice shall be"
echo " included in all copies or substantial portions of the Software."
echo " "
echo " THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, "
echo " INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A"
echo " PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT" 
echo " HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION"
echo " OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE "
echo " OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
echo " "

if [[ $2 != yes ]];then
read -p " Did you read and accept the terms and conditions? (yes/no) "  
if [[ $REPLY != yes ]]
then
    exit 1
fi
fi 

echo ""
echo ""
echo ""

if [[ $2 != yes ]];then
echo " This script downloads the external software SNAP, which is licensed under the GNU GPL version 3 and can be found here"
echo " https://www.gnu.org/licenses/gpl.html"
echo ""
read -p " Do you accept the terms and conditions of the use of the SNAP software  (yes/no) "  
if [[ $REPLY != yes ]]
then
    exit 1
fi
fi


mkdir -p ${OSK_HOME}
mkdir -p ${OSK_HOME}/LOG

#----------------------------------
# 1 Adding extra repositories
#----------------------------------

SECONDS=0
echo -ne " Adding the Ubuntu GIS unstable repository ..." &&
add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable > ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"


SECONDS=0
echo -ne " Adding the multiverse repository ..." &&
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main multiverse"  >> ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

#QGIS for 14.04
# add lines to sources

if grep -q "qgis.org/ubuntugis" /etc/apt/sources.list;then 
	echo " Yeah, you are already a QGIS user, nice!"
else

	echo " "
	echo " Adding the QGIS repository"
	echo " Note: QGIS will not be installed, in order to do so type: " 
	echo " sudo apt-get install --yes qgis libqgis-dev"
	echo " "
	echo "deb http://qgis.org/ubuntugis $(lsb_release -sc) main" >> /etc/apt/sources.list
	echo "deb-src http://qgis.org/ubuntugis $(lsb_release -sc) main" >> /etc/apt/sources.list
	# add key
	apt-key adv --keyserver keyserver.ubuntu.com --recv-key 3FF5FFCAD71472C4 >> ${OSK_HOME}/LOG/log_install 2>&1
fi

#------------------------------------------------------------------
# 2 run update to load new packages and upgrade all installed ones
#------------------------------------------------------------------

SECONDS=0
echo -ne " Updating the system ..." &&
apt-get update -y >> ${OSK_HOME}/LOG/log_install 2>&1 && \
apt-get upgrade -y  >> ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

#------------------------------------------------------------------
# 3 install packages
#------------------------------------------------------------------

SECONDS=0
echo -ne " Installing dependencies from Ubuntu package list ..." &&
apt-get install --yes gdal-bin libgdal-dev python-gdal saga libsaga-dev python-saga geotiff-bin libgeotiff-dev dans-gdal-scripts spatialite-bin spatialite-gui \
python-scipy python-h5py aria2 unrar parallel xml-twig-tools git >> ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"
#libcunit1-dev libfftw3-dev libshp-dev libgeotiff-dev libtiff4-dev libtiff5-dev libproj-dev flex bison libgsl0-dev gsl-bin  libglade2-dev libgtk2.0-dev libgdal-dev pkg-config \

# Dependencies for PolSARPro
#apt-get install --yes bwidget itcl3 itk3 iwidgets4 libtk-img 

#------------------------------------------------------------------
# 3 Download & Install non-repository Software and OSK
#------------------------------------------------------------------

#-------------------------------------
# get OSK from github repository
if [ -z "$OSK_GIT_URL" ]; then export OSK_GIT_URL=https://github.com/openforis/opensarkit; fi
mkdir -p ${OSK_HOME}
cd ${OSK_HOME}

OSK_VERSION=0.1-beta

# write a preliminary source file
echo '#! /bin/bash' > ${OSK_HOME}/OpenSARKit_source.bash
echo "" >> ${OSK_HOME}/OpenSARKit_source.bash

echo "export OSK_VERSION=${OSK_VERSION}" >> ${OSK_HOME}/OpenSARKit_source.bash

echo '# Support script to source the original programs' >> ${OSK_HOME}/OpenSARKit_source.bash
echo "export OSK_HOME=${OSK_HOME}" >> ${OSK_HOME}/OpenSARKit_source.bash

echo '# Folder of OpenSARKit scripts and workflows' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export OPENSARKIT=${OSK_HOME}/opensarkit' >> ${OSK_HOME}/OpenSARKit_source.bash

echo '# source auxiliary Spatialite database' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export DB_GLOBAL=${OSK_HOME}/Database/global_info.sqlite' >> ${OSK_HOME}/OpenSARKit_source.bash	 

#echo '# source lib-functions' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'source ${OPENSARKIT}/lib/gdal_helpers' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'source ${OPENSARKIT}/lib/saga_helpers' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'source ${OPENSARKIT}/lib/s1_helpers' >> ${OSK_HOME}/OpenSARKit_source.bash

echo '# source workflows/graphs' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export SNAP_GRAPHS=${OPENSARKIT}/workflows/SNAP' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export ASF_CONF=${OPENSARKIT}/workflows/ASF' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export POLSAR_CONF=${OPENSARKIT}/workflows/POLSAR' >> ${OSK_HOME}/OpenSARKit_source.bash
# 
echo '# export bins' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export SNAP_BIN=${OPENSARKIT}/bins/SNAP' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export ASF_BIN=${OPENSARKIT}/bins/ASF' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export KC_BIN=${OPENSARKIT}/bins/KC' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export REMOTE_BIN=${OPENSARKIT}/bins/Remote_scripts' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export DOWNLOAD_BIN=${OPENSARKIT}/bins/Download' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export PYTHON_BIN=${OPENSARKIT}/python' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export GDAL_BIN=${OPENSARKIT}/bins/GDAL' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export SAGA_BIN=${OPENSARKIT}/bins/SAGA' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export RSGISLIB_BIN=${OPENSARKIT}/bins/RSGISLIB' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export PROGRAMS=${OSK_HOME}/Programs' >> ${OSK_HOME}/OpenSARKit_source.bash

# get OpenSARKit from github
SECONDS=0
echo -ne " Getting the Open Foris SAR Toolkit ..." &&
git clone $OSK_GIT_URL >> ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"
#-------------------------------------


# install dependend Software
mkdir -p ${OSK_HOME}/Programs
cd ${OSK_HOME}/Programs

#-------------------------------------
# Install ASF Mapready

# check if installed
#if [ `which asf_mapready | wc -c` -gt 0 ];then 

#	AOI_EXE=`dirname \`which asf_mapready\``
#	echo 'export AOI_EXE=${AOI_EXE}' >> ${OSK_HOME}/OpenSARKit_source.bash

#else

	#git clone https://github.com/asfadmin/ASF_MapReady
#	SECONDS=0
#	echo -ne " Downloading ASF MapReady from ASF server ..." &&
#	wget https://github.com/asfadmin/ASF_MapReady/archive/3.6.6-117.tar.gz  >> ${OSK_HOME}/LOG/log_install 2>&1 \
#	& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

#	SECONDS=0
#	echo -ne " Extracting ASF MapReady archive ..." &&
#	tar -xzvf ${OSK_HOME}/Programs/3.6.6-117.tar.gz  >> ${OSK_HOME}/LOG/log_install 2>&1 \
#	& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

#	rm -f ${OSK_HOME}/Programs/3.6.6-117.tar.gz 
#	cd ASF_MapReady-3.6.6-117 

#	SECONDS=0
#	echo -ne " Installing ASF MapReady ..." 
#	./configure --prefix=${OSK_HOME}/Programs/ASF_bin >> ${OSK_HOME}/LOG/log_install 2>&1 & spinner $! 
#	make >> ${OSK_HOME}/LOG/log_install 2>&1 & spinner $! 
#	make install >> ${OSK_HOME}/LOG/log_install 2>&1 \
#	& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

#	echo 'export ASF_EXE=${PROGRAMS}/ASF_bin/bin' >> ${OSK_HOME}/OpenSARKit_source.bash
#fi 
#-------------------------------------

#-------------------------------------
# Insatll PolsARPro
#if [ `which alos_header.exe | wc -c` -gt 0 ];then 

#	POLSAR_PRE=`dirname \`which alos_header.exe\``
#	cd ${POLSAR_PRE}/../
#	POLSAR=`pwd`
#	echo 'export POLSAR=${POLSAR}' >> ${OSK_HOME}/OpenSARKit_source.bash
#	echo 'export POLSAR_BIN=${POLSAR}/data_import:${POLSAR}/data_convert:${POLSAR}/speckle_filter:${POLSAR}/bmp_process:${POLSAR}/tools' >> ${OSK_HOME}/OpenSARKit_source.bash

#else

	# PolSARPro
#	mkdir -p ${OSK_HOME}/Programs/PolSARPro504
#	cd ${OSK_HOME}/Programs/PolSARPro504
#	wget https://earth.esa.int/documents/653194/1960708/PolSARpro_v5.0.4_Linux_20150607
#	unrar x PolSARpro_v5.0.4_Linux_20150607
#	cd Soft
#	bash Compil_PolSARpro_v5_Linux.bat 
#	POLSAR=`pwd` 
#	echo 'export POLSAR=${PROGRAMS}/PolSARPro504/Soft' >> ${OSK_HOME}/OpenSARKit_source.bash
#	echo 'export POLSAR_BIN=${POLSAR}/data_import:${POLSAR}/data_convert:${POLSAR}/speckle_filter:${POLSAR}/bmp_process:${POLSAR}/tools' >> ${OSK_HOME}/OpenSARKit_source.bash
#fi
#-------------------------------------

#-------------------------------------
# Install SNAP
# check if installed
if [ `which snap | wc -c` -gt 0 ];then 

	SNAP=`dirname \`which gpt\``
	echo 'export SNAP=${SNAP}' >> ${OSK_HOME}/OpenSARKit_source.bash
	echo 'export SNAP_EXE=${SNAP}/bin/gpt'  >> ${OSK_HOME}/OpenSARKit_source.bash
else
	cd ${OSK_HOME}/Programs/
	
	SECONDS=0
	echo -ne " Downloading the SNAP software ..." &&
	wget http://step.esa.int/downloads/3.0/installers/esa-snap_sentinel_unix_3_0.sh  >> ${OSK_HOME}/LOG/log_install 2>&1 \
	& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

	SECONDS=0
	echo -ne " Installing the SNAP software ..." &&
	sh esa-snap_sentinel_unix_3_0.sh -q -overwrite  >> ${OSK_HOME}/LOG/log_install 2>&1 \
	& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

	rm -f esa-snap_sentinel_unix_3_0.sh
	echo 'export SNAP=/usr/local/snap' >> ${OSK_HOME}/OpenSARKit_source.bash
	echo 'export SNAP_EXE=${SNAP}/bin/gpt'  >> ${OSK_HOME}/OpenSARKit_source.bash


fi

#-------------------------------------

#-------------------------------------
## Adding executalble to path for CL availability
echo '#export to Path' >> ${OSK_HOME}/OpenSARKit_source.bash
#echo 'export PATH=$PATH:${PYTHON_BIN}:${RSGISLIB_BIN}:${ASF_BIN}:${POLSAR_BIN}:${SAGA_BIN}:${SNAP_BIN}:${GDAL_BIN}:${DOWNLOAD_BIN}:${ASF_EXE}:${SNAP}:${KC_BIN}:${REMOTE_BIN}' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export PATH=$PATH:${SNAP_BIN}:${DOWNLOAD_BIN}:${SNAP}:${KC_BIN}:${ASF_BIN}' >> ${OSK_HOME}/OpenSARKit_source.bash
# Update global environment variables"
mv ${OSK_HOME}/OpenSARKit_source.bash /etc/profile.d/OpenSARKit.sh
chmod -R 755 ${OSK_HOME}
source /etc/profile.d/OpenSARKit.sh
#-------------------------------------

# update SNAP
SECONDS=0
echo -ne " Updating SNAP to the latest version ..." &&
snap --nosplash --nogui --modules --update-all  >> ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

HOME_USER=`stat -c '%U' ${HOME}/.snap`
chown -R ${HOME_USER}:${HOME_USER} ${HOME}/.snap

#------------------------------------------------------------------
# 3 Download the additional Database
#------------------------------------------------------------------

mkdir -p ${OSK_HOME}/Database
cd ${OSK_HOME}/Database

SECONDS=0
echo -ne " Downloading the OFST database ..." &&
wget https://www.dropbox.com/s/58cnjj8xymzkbac/global_info.sqlite?dl=0  >> ${OSK_HOME}/LOG/log_install 2>&1 \
& spinner $! && duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

mv global_info.sqlite?dl=0 global_info.sqlite

echo "---------------------------------------------------------------------------------------------------------------------------"
echo " Installation of OFST succesfully completed"
echo " In order to be able to launch the scripts immediately on the command line, type: source /etc/profile.d/OpenSARKit.sh "
echo " Otherwise restart your computer"
echo "---------------------------------------------------------------------------------------------------------------------------"
