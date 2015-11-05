#! /bin/bash

VERSION="Version 0.1"

if [ "$#" == "0" ];then

	echo -e ""
	echo -e "----------------------------------"
	echo -e " OpenSARKit, ${VERSION}"
	echo -e " Install script"
	echo -e " Developed by: Food and Agriculture Organization of the United Nations, Rome"
#	echo -e " Author: Andreas Vollrath"
	echo -e "----------------------------------"
	echo -e ""
	export OSK_HOME=/usr/local/lib/osk

elif [ "$#" == "1" ];then

	echo -e ""
	echo -e "----------------------------------"
	echo -e " OpenSARKit, ${VERSION}"
	echo -e " Install script"
	echo -e " Developed by: Food and Agriculture Organization of the United Nations, Rome"
#	echo -e " Author: Andreas Vollrath"
	echo -e "----------------------------------"
	echo -e ""
	export OSK_HOME=$1

else 

	echo -e ""
	echo -e "----------------------------------"
	echo -e " OpenSARKit, ${VERSION}"
	echo -e " Install script"
	echo -e " Developed by: Food and Agriculture Organization of the United Nations, Rome"
#	echo -e " Author: Andreas Vollrath"
	echo -e "----------------------------------"
	echo -e ""

	echo -e " syntax: install_osk <installation_folder>"
	echo -e ""
	echo -e " description of input parameters:"
	echo -e " installation_folder		(output) path to installation folder of OSK"
	exit 1
fi

#----------------------------------
# 1 Adding extra repositories
#----------------------------------
## I GIS packages from ubuntugis (unstable)
add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable

## II InSAR Packages Antonio Valentinos eotools 
add-apt-repository -y ppa:a.valentino/eotools

## III Java Official Packages
add-apt-repository -y ppa:webupd8team/java

## Enable multiverse for unrar
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main multiverse"

#QGIS for 14.04
# add lines to sources
#if grep -q "qgis.org/ubuntugis" /etc/apt/sources.list;then 
#	echo "Yeah, you are QGIS user, nice!"
#else
#	echo "deb http://qgis.org/ubuntugis $(lsb_release -sc) main" >> /etc/apt/sources.list
#	echo "deb-src http://qgis.org/ubuntugis $(lsb_release -sc) main" >> /etc/apt/sources.list
	# add key
#	apt-key adv --keyserver keyserver.ubuntu.com --recv-key 3FF5FFCAD71472C4
#fi

#------------------------------------------------------------------
# 2 run update to load new packages and upgrade all installed ones
#------------------------------------------------------------------
apt-get update -y
apt-get upgrade -y 


#------------------------------------------------------------------
# 3 install packages
#------------------------------------------------------------------
# Gis Packages
#apt-get install --yes qgis gdal-bin libgdal-dev python-gdal saga libsaga-dev python-saga otb-bin libotb-dev libotb-ice libotb-ice-dev monteverdi2 python-otb geotiff-bin libgeotiff-dev gmt libgmt-dev dans-gdal-scripts
#libqgis-dev (problems with grass 7)
apt-get install --yes gdal-bin libgdal-dev python-gdal saga libsaga-dev python-saga geotiff-bin libgeotiff-dev dans-gdal-scripts

## Spatial-Database Spatialite
apt-get install --yes spatialite-bin spatialite-gui #pgadmin3 postgresql postgis

# Dependencies for ASF Mapready
apt-get install --yes libcunit1-dev libfftw3-dev libshp-dev libgeotiff-dev libtiff4-dev libtiff5-dev libproj-dev gdal-bin flex bison libgsl0-dev gsl-bin git libglade2-dev libgtk2.0-dev libgdal-dev pkg-config

## Java official
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections \
    && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections # Enable silent install of Java
apt-get install --yes oracle-java8-installer oracle-java8-set-default

## Python libraries
apt-get install --yes python-scipy python-h5py python-pyresample  

# Dependencies for PolSARPro
apt-get install --yes bwidget itcl3 itk3 iwidgets4 libtk-img 

# Further tools (i.e. Aria for automated ASF download, unrar for unpacking, parallel for parallelization of processing)
apt-get install --yes aria2 unrar parallel xml-twig-tools

## LEDAPS
#apt-get install --yes zlib1g zlib1g-dev libtiff5 libtiff5-dev libgeotiff2 libgeotiff-dev libxml2 libxml2-dev ksh libhdf4-0 libhdf4-0-alt libhdf4-alt-dev libhdfeos0 libhdfeos-dev libgctp0d libgctp-dev hdf4-tools


#------------------------------------------------------------------
# 3 Download & Install non-repository Software and OSK
#------------------------------------------------------------------


if [ -z "$OSK_GIT_URL" ]; then export OSK_GIT_URL=https://github.com/BuddyVolly/OpenSARKit; fi
mkdir -p ${OSK_HOME}
cd ${OSK_HOME}

VERSION=0.1

# write a source file
echo '#! /bin/bash' > ${OSK_HOME}/OpenSARKit_source.bash
echo '' >> ${OSK_HOME}/OpenSARKit_source.bash
echo "export VERSION=${VERSION}" >> ${OSK_HOME}/OpenSARKit_source.bash
echo '# Support script to source the original programs' >> ${OSK_HOME}/OpenSARKit_source.bash
echo "export OSK_HOME=${OSK_HOME}" >> ${OSK_HOME}/OpenSARKit_source.bash
echo '# Folder of OpenSARKit scripts and workflows' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export OPENSARKIT=${OSK_HOME}/OpenSARKit' >> ${OSK_HOME}/OpenSARKit_source.bash
echo '# source auxiliary Spatialite database' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export DB_GLOBAL=${OPENSARKIT}/Database/global_info.sqlite' >> ${OSK_HOME}/OpenSARKit_source.bash	 
echo '# source lib-functions' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'source ${OPENSARKIT}/lib/bash_helpers.sh' >> ${OSK_HOME}/OpenSARKit_source.bash
echo '# source worklows/graphs' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export NEST_GRAPHS=${OPENSARKIT}/workflows/NEST' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export S1TBX_GRAPHS=${OPENSARKIT}/workflows/S1TBX' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export ASF_CONF=${OPENSARKIT}/workflows/ASF' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export POLSAR_CONF=${OPENSARKIT}/workflows/POLSAR' >> ${OSK_HOME}/OpenSARKit_source.bash
echo '# source worklows/graphs' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export NEST_BIN=${OPENSARKIT}/bins/NEST' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export S1TBX_BIN=${OPENSARKIT}/bins/S1TBX' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export ASF_BIN=${OPENSARKIT}/bins/ASF' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export DOWNLOAD_BIN=${OPENSARKIT}/download_scripts' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export PYTHON_BIN=${OPENSARKIT}/python' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export GDAL_BIN=${OPENSARKIT}/bins/GDAL' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export SAGA_BIN=${OPENSARKIT}/bins/SAGA' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export RSGISLIB_BIN=${OPENSARKIT}/bins/RSGISLIB' >> ${OSK_HOME}/OpenSARKit_source.bash

# get OpenSARKit from github
git clone $OSK_GIT_URL

# install dependend Software
mkdir -p ${OSK_HOME}/Programs
cd ${OSK_HOME}/Programs

#ASF Mapready

# check if installed
if [ `which asf_mapready | wc -c` -gt 0 ];then 

	AOI_EXE=`dirname \`which asf_mapready\``
	echo 'export AOI_EXE=${AOI_EXE}' >> ${OSK_HOME}/OpenSARKit_source.bash

else

	#git clone https://github.com/asfadmin/ASF_MapReady
	wget https://github.com/asfadmin/ASF_MapReady/archive/3.6.6-117.tar.gz
	tar -xzvf ${OSK_HOME}/Programs/3.6.6-117.tar.gz
	rm -f ${OSK_HOME}/Programs/3.6.6-117.tar.gz
	cd ASF_MapReady-3.6.6-117
	./configure --prefix=${OSK_HOME}/Programs/ASF_bin
	make
	make install
	echo 'export ASF_EXE=${PROGRAMS}/ASF_bin/bin' >> ${OSK_HOME}/OpenSARKit_source.bash
fi 

if [ `which alos_header.exe | wc -c` -gt 0 ];then 

	POLSAR_PRE=`dirname \`which alos_header.exe\``
	cd ${POLSAR_PRE}/../
	POLSAR=`pwd`
	echo 'export POLSAR=${POLSAR}' >> ${OSK_HOME}/OpenSARKit_source.bash
	echo 'export POLSAR_BIN=${POLSAR}/data_import:${POLSAR}/data_convert:${POLSAR}/speckle_filter:${POLSAR}/bmp_process:${POLSAR}/tools' >> ${OSK_HOME}/OpenSARKit_source.bash

else

	# PolSARPro
	mkdir -p ${OSK_HOME}/Programs/PolSARPro504
	cd ${OSK_HOME}/Programs/PolSARPro504
	wget https://earth.esa.int/documents/653194/1960708/PolSARpro_v5.0.4_Linux_20150607
	unrar x PolSARpro_v5.0.4_Linux_20150607
	cd Soft
	bash Compil_PolSARpro_v5_Linux.bat 
	POLSAR=`pwd` 
	echo 'export POLSAR=${PROGRAMS}/PolSARPro504/Soft' >> ${OSK_HOME}/OpenSARKit_source.bash
	echo 'export POLSAR_BIN=${POLSAR}/data_import:${POLSAR}/data_convert:${POLSAR}/speckle_filter:${POLSAR}/bmp_process:${POLSAR}/tools' >> ${OSK_HOME}/OpenSARKit_source.bash
fi

# SNAP
# check if installed
if [ `which s1tbx | wc -c` -gt 0 ];then 

	S1TBX=`dirname \`which s1tbx\``
	echo 'export S1TBX=${S1TBX}' >> ${OSK_HOME}/OpenSARKit_source.bash
	echo 'export S1TBX_EXE=${S1TBX}/gpt.sh'  >> ${OSK_HOME}/OpenSARKit_source.bash
else
	cd ${OSK_HOME}/Programs/
	wget http://sentinel1.s3.amazonaws.com/1.0/s1tbx_1.1.1_Linux64_installer.sh
	sh s1tbx_1.1.1_Linux64_installer.sh -q -overwrite
	rm -f s1tbx_1.1.1_Linux64_installer.sh
	echo 'export S1TBX=${PROGRAMS}/S1TBX' >> ${OSK_HOME}/OpenSARKit_source.bash
	echo 'export S1TBX_EXE=${S1TBX}/gpt.sh'  >> ${OSK_HOME}/OpenSARKit_source.bash
fi

echo '#export to Path' >> ${OSK_HOME}/OpenSARKit_source.bash
echo 'export PATH=$PATH:${PYTHON_BIN}:${RSGISLIB_BIN}:${ASF_BIN}:${POLSAR_BIN}:${SAGA_BIN}:${S1TBX_BIN}:${NEST_BIN}:${GDAL_BIN}:${DOWNLOAD_BIN}:${ASF_EXE}:${S1TBX}' >> ${OSK_HOME}/OpenSARKit_source.bash

# Update global environment variables"
cp ${OSK_HOME}/OpenSARKit/OpenSARKit_source.bash /etc/profile.d/OpenSARKit.sh
chmod -R 755 ${OSK_HOME}

#------------------------------------------------------------------
# 3 Download the additional Database
#------------------------------------------------------------------

mkdir -p ${OSK_HOME}/Database
cd ${OSK_HOME}/Database
wget https://www.dropbox.com/s/58cnjj8xymzkbac/global_info.sqlite?dl=0

echo "--------------------------------"
echo " Installation of OFSK completed"
echo "--------------------------------"
