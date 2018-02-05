#!/bin/bash

# The MIT License (MIT)
# Copyright (c) 2016 Andreas Vollrath

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

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

# Licenses
echo " The MIT License (MIT)"
echo " Copyright (c) 2016 Andreas Vollrath"
echo " "
echo " Permission is hereby granted, free of charge, to any person obtaining a copy"
echo " of this software and associated documentation files (the \"Software\"), to deal "
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
OPENSARKIT=${OSK_HOME}/opensarkit

#----------------------------------
# 1 Adding extra repositories
#----------------------------------

RELEASE=`lsb_release -sc`

SECONDS=0
echo -ne " Adding the Ubuntu GIS unstable repository ..." &&
add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable > ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"


SECONDS=0
echo -ne " Adding the multiverse repository ..." &&
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu/ ${RELEASE} main multiverse"  >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

## IX R-CRAN from R mirror
if grep -q "qgis.org/ubuntugis" /etc/apt/sources.list;then

	echo "detected cran repository for R installation"
else
	add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu ${RELEASE}/"
	#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
	gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9 >> ${OSK_HOME}/LOG/log_install 2>&1
	gpg -a --export E084DAB9 | apt-key add - >> ${OSK_HOME}/LOG/log_install 2>&1
fi

if grep -q "qgis.org/ubuntugis" /etc/apt/sources.list;then
	echo " Yeah, you are already a QGIS user, nice!"
else

	echo " "
	echo " Adding the QGIS repository"
	echo " Note: QGIS will not be installed, in order to do so type: "
	echo " sudo apt-get install --yes qgis libqgis-dev"
	echo " "
	echo "deb http://qgis.org/ubuntugis ${RELEASE} main" >> /etc/apt/sources.list
	echo "deb-src http://qgis.org/ubuntugis ${RELEASE} main" >> /etc/apt/sources.list
	# add key
	#apt-key adv --keyserver keyserver.ubuntu.com --recv-key 073D307A618E5811 >> ${OSK_HOME}/LOG/log_install 2>&1
	#apt-key adv --keyserver keyserver.ubuntu.com --recv-key 073D307A618E5811

	wget -O - http://qgis.org/downloads/qgis-2016.gpg.key | gpg --import >> ${OSK_HOME}/LOG/log_install 2>&1
	gpg --export --armor 073D307A618E5811 | apt-key add - >> ${OSK_HOME}/LOG/log_install 2>&1
fi

#------------------------------------------------------------------
# 2 run update to load new packages and upgrade all installed ones
#------------------------------------------------------------------

SECONDS=0
echo -ne " Updating the system ..."
apt-get update -y >> ${OSK_HOME}/LOG/log_install 2>&1
apt-get upgrade -y >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

#------------------------------------------------------------------
# 3 install packages
#------------------------------------------------------------------

SECONDS=0
echo -ne " Installing GIS/Remote sensing packages ..."
apt-get install --yes --allow-unauthenticated \
											gdal-bin \
											dbview \
											libgdal-dev \
 										  dans-gdal-scripts \
											saga \
											libsaga-dev \
										#	otb-bin \
										# libotb \
 										#	libotb-apps \
											geotiff-bin \
											libgeotiff-dev \
											spatialite-bin \
											spatialite-gui >> ${OSK_HOME}/LOG/log_install_gis 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"


SECONDS=0
echo -ne " Installing Ubuntu package dependencies "
apt-get install --yes --allow-unauthenticated \
											mlocate \
											libcunit1-dev \
											libfftw3-dev \
											libshp-dev \
											libtiff5-dev \
											libproj-dev \
											flex \
											bison \
											libgsl0-dev \
											gsl-bin \
											libglade2-dev \
											libgmp-dev \
											libgtk2.0-dev \
											pkg-config \
											aria2 \
											curl \
											unrar \
											p7zip-full \
											parallel \
											xml-twig-tools \
											git \
											libudunits2-dev \
											libxinerama-dev \
											libxrandr-dev \
											libxcursor-dev \
											swig \
											r-base \
											libv8-3.14-dev >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

SECONDS=0
echo -ne " Installing python 2.7 packages "
apt-get install --yes --allow-unauthenticated \
											python-dev \
											python-gdal \
											python-saga \
										#	python-otb \
											python-scipy \
											python-h5py \
											python-skimage \
											python-statsmodels \
											python-pandas \
											python-geopandas \
											python-geopy \
											python-progressbar \
											python-opencv \
											python-rasterio \
											python-sklearn \
											python-numpy >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

echo ""
echo "-------------------------------------"
echo "--- Installing Orfeo ToolBox ---"
echo "-------------------------------------"

# install the latest Orfeo packaged version for use of ORFEO remote modules
#otb=OTB-contrib-5.10.1-Linux64
otb=OTB-contrib-6.0.0-Linux64
wget https://www.orfeo-toolbox.org/packages/$otb.run
chmod +x $otb.run
mv $otb.run /usr/local/lib
cd /usr/local/lib
./$otb.run
rm $otb.run
ln -s $otb orfeo
chmod o+rx orfeo/*.sh
chmod o+rx orfeo/otbenv.profile
cd -
echo "PYTHONPATH=/usr/local/lib/OTB-contrib-6.0.0-Linux64/lib/python" >> /etc/environment
echo "PATH=${PATH}:/usr/local/lib/orfeo/bin" >> /etc/environment

#------------------------------------------------------------------
# 4 Download & Install non-repository Software and OSK
#------------------------------------------------------------------

#-------------------------------------
# get OSK from github repository
if [ -z "$OSK_GIT_URL" ]; then export OSK_GIT_URL=https://github.com/openforis/opensarkit; fi
mkdir -p ${OSK_HOME}
cd ${OSK_HOME}

# get OpenSARKit from github
SECONDS=0
echo -ne " Getting the Open SAR Toolkit ..." &&
#wget https://github.com/openforis/opensarkit/archive/v0.1-alpha.1.tar.gz
#tar -xzf v0.1-alpha.1.tar.gz
git clone $OSK_GIT_URL >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"


OSK_VERSION=0.1-beta

cd ${OSK_HOME}/opensarkit/bins

BINDIR=/usr/local/bin/

for OST_BINS in `ls -1 -d */`;do

	cd $OST_BINS
	for exe in `ls -1 {ost_*,post_*} 2>/dev/null`;do

		exepath=`readlink -f $exe`
		ln -s $exepath ${BINDIR}/

	done

	cd ../
done

#-------------------------------------
# Install SNAP
# check if installed
updatedb

if [ `locate gpt.vmoptions | wc -c` -gt 0 ];then

	SNAP_DIR=`locate gpt.vmoptions`
	SNAP=`dirname ${SNAP_DIR}`
	echo " Adding environmental variables to /etc/environment ..."
	echo "OPENSARKIT=${OSK_HOME}/opensarkit" | tee -a /etc/environment
	echo "OST_DB=${OSK_HOME}/Database/OFST_db.sqlite" | tee -a /etc/environment
	echo "SNAP_EXE=${SNAP}/gpt" | tee -a /etc/environment

else

	SECONDS=0
	echo -ne " Downloading the SNAP software ..." &&
	wget http://step.esa.int/downloads/6.0/installers/esa-snap_sentinel_unix_6_0.sh  >> ${OSK_HOME}/LOG/log_install 2>&1
	duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

	SECONDS=0
	echo -ne " Installing the SNAP software ..." &&
	sh esa-snap_sentinel_unix_6_0.sh -q -overwrite  >> ${OSK_HOME}/LOG/log_install 2>&1
	duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

	rm -f esa-snap_sentinel_unix_5_0.sh

	echo -ne " Adding environmental variables to /etc/environment ..."
	echo "OPENSARKIT=${OSK_HOME}/opensarkit" | tee -a /etc/environment
	echo "OST_DB=${OSK_HOME}/Database/OFST_db.sqlite" | tee -a /etc/environment
	echo 'SNAP_EXE=/usr/local/snap/bin/gpt' | tee -a /etc/environment


fi

# update SNAP
SECONDS=0
echo -ne " Updating SNAP to the latest version ..." &&
#/usr/local/snap/bin/snap
snap --nosplash --nogui --modules --update-all  >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

HOME_USER=`stat -c '%U' ${HOME}/.bashrc`
chown -R ${HOME_USER}:${HOME_USER} ${HOME}/.snap

#-------------------------------------

#------------------------------------------------------------------
# 5 Download the additional Database
#------------------------------------------------------------------

mkdir -p ${OSK_HOME}/Database
cd ${OSK_HOME}/Database

SECONDS=0
echo -ne " Downloading the OST database ..." &&
wget https://www.dropbox.com/s/qvujm3l0ba0frch/OFST_db.sqlite?dl=0  >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"
mv OFST_db.sqlite?dl=0 OFST_db.sqlite


echo -ne " Installing R packages for shiny app ..." &&
/usr/bin/R -e "install.packages('shiny', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('shinydashboard', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('shinyFiles', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('shinyjs', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('RSQLite', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('RColorBrewer', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('random', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('raster', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('mapview', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('rknn', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OSK_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

echo -ne " Creating a start up icon on the Desktop ..."

echo "[Desktop Entry]" > ${HOME}/Desktop/OST.desktop
echo "Version=1.0" >> ${HOME}/Desktop/OST.desktop
echo "Name=Open SAR Toolkit" >> ${HOME}/Desktop/OST.desktop
echo "Comment=" >> ${HOME}/Desktop/OST.desktop
echo 'Exec=bash -c "R CMD BATCH ${OPENSARKIT}/shiny/ost.R;$SHELL"' >> ${HOME}/Desktop/OST.desktop
echo "Icon=${OPENSARKIT}/OST_icon_trans.png" >> ${HOME}/Desktop/OST.desktop
echo "Terminal=true" >> ${HOME}/Desktop/OST.desktop
echo "Type=Application" >> ${HOME}/Desktop/OST.desktop
echo "Categories=Application;" >> ${HOME}/Desktop/OST.desktop
echo "Path=" >> ${HOME}/Desktop/OST.desktop
echo "StartupNotify=false" >> ${HOME}/Desktop/OST.desktop

echo "require(shiny)" > ${OPENSARKIT}/shiny/ost.R
echo "runApp('${OPENSARKIT}/shiny/',launch.browser = T)" >> ${OPENSARKIT}/shiny/ost.R

chmod +x ${HOME}/Desktop/OST.desktop
chown ${HOME_USER}:${HOME_USER} ${HOME}/Desktop/OST.desktop

cp ${HOME}/Desktop/OST.desktop /usr/share/applications/OST.desktop

duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

echo "---------------------------------------------------------------------------------------------------------------------------"
echo " Installation of OST succesfully completed"
echo " In order to be able to launch the scripts immediately on the command line, type: source /etc/environment "
echo " Otherwise restart your computer"
echo "---------------------------------------------------------------------------------------------------------------------------"
