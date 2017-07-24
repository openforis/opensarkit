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

#----------------------------------
# 1 Adding extra repositories
#----------------------------------

OST_HOME=$(cat /etc/environment | grep OPENSARKIT | awk -F '=' '{print $2}')
echo "ost: $OST_HOME"
RELEASE=`lsb_release -sc`

SECONDS=0
echo -ne " Adding the Ubuntu GIS unstable repository ..." &&
add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"


SECONDS=0
echo -ne " Adding the multiverse repository ..." &&
add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu/ ${RELEASE} main multiverse"  >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

## IX R-CRAN from R mirror
if grep -q "qgis.org/ubuntugis" /etc/apt/sources.list;then

	echo "detected cran repository for R installation"
else
	add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu ${RELEASE}/"
	gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9 >> ${OST_HOME}/LOG/log_install 2>&1
	gpg -a --export E084DAB9 | apt-key add - >> ${OST_HOME}/LOG/log_install 2>&1
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
	#apt-key adv --keyserver keyserver.ubuntu.com --recv-key 073D307A618E5811 >> ${OST_HOME}/LOG/log_install 2>&1
	#apt-key adv --keyserver keyserver.ubuntu.com --recv-key 073D307A618E5811

	wget -O - http://qgis.org/downloads/qgis-2016.gpg.key | gpg --import >> ${OST_HOME}/LOG/log_install 2>&1
	gpg --export --armor 073D307A618E5811 | apt-key add - >> ${OST_HOME}/LOG/log_install 2>&1
fi

#------------------------------------------------------------------
# 2 run update to load new packages and upgrade all installed ones
#------------------------------------------------------------------

SECONDS=0
echo -ne " Updating the system ..."
apt-get update -y >> ${OST_HOME}/LOG/log_install 2>&1
apt-get upgrade -y >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

#------------------------------------------------------------------
# 3 install packages
#------------------------------------------------------------------

SECONDS=0
echo -ne " Installing GIS/Remote sensing packages ..."
apt-get install --yes --allow-unauthenticated \
											gdal-bin \
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
											spatialite-gui >> ${OST_HOME}/LOG/log_install_gis 2>&1
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
											libv8-3.14-dev >> ${OST_HOME}/LOG/log_install 2>&1
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
											python-numpy >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

echo ""
echo "-------------------------------------"
echo "--- Installing Orfeo ToolBox ---"
echo "-------------------------------------"

# install the latest Orfeo packaged version for use of ORFEO remote modules
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

updatedb

SECONDS=0
echo -ne " Downloading the SNAP software ..." &&
wget http://step.esa.int/downloads/5.0/installers/esa-snap_sentinel_unix_5_0.sh  >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

SECONDS=0
echo -ne " Installing the SNAP software ..." &&
sh esa-snap_sentinel_unix_5_0.sh -q -overwrite  >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

rm -f esa-snap_sentinel_unix_5_0.sh

echo -ne " Adding environmental variables to /etc/environment ..."
echo 'SNAP_EXE=/usr/local/snap/bin/gpt' | tee -a /etc/environment

# update SNAP
SECONDS=0
echo -ne " Updating SNAP to the latest version ..." &&
#/usr/local/snap/bin/snap
snap --nosplash --nogui --modules --update-all  >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

HOME_USER=`stat -c '%U' ${HOME}/.bashrc`
chown -R ${HOME_USER}:${HOME_USER} ${HOME}/.snap

#-------------------------------------

#------------------------------------------------------------------
# 5 Download the additional Database
#------------------------------------------------------------------

echo -ne " Installing R packages for shiny app ..." &&
/usr/bin/R -e "install.packages('shiny', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('shinydashboard', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('shinyFiles', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('shinyjs', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('RSQLite', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('RColorBrewer', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('random', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('raster', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('mapview', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
/usr/bin/R -e "install.packages('rknn', dependencies=TRUE, repos='http://cran.rstudio.com/')" >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

echo "---------------------------------------------------------------------------------------------------------------------------"
echo " Installation of OST dependencies succesfully completed"
echo "---------------------------------------------------------------------------------------------------------------------------"
