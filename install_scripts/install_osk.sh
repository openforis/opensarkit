#! /bin/bash

# install dependencies of ASF

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
echo "deb http://qgis.org/ubuntugis $(lsb_release -sc) main" >> /etc/apt/sources.list
echo "deb-src http://qgis.org/ubuntugis $(lsb_release -sc) main" >> /etc/apt/sources.list
# add key
apt-key adv --keyserver keyserver.ubuntu.com --recv-key 3FF5FFCAD71472C4


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

export OSK_HOME=/usr/local/lib/osk
if [ -z "$OSK_GIT_URL" ]; then export OSK_GIT_URL=https://github.com/BuddyVolly/OpenSARKit; fi
mkdir ${OSK_HOME}
cd ${OSK_HOME}

# OpenSARKit
git clone $OSK_GIT_URL

#ASF Mapready

mkdir -p ${OSK_HOME}/Programs
cd ${OSK_HOME}/Programs

#git clone https://github.com/asfadmin/ASF_MapReady
wget https://github.com/asfadmin/ASF_MapReady/archive/3.6.6-117.tar.gz
tar -xzvf ${OSK_HOME}/Programs/3.6.6-117.tar.gz
rm -f ${OSK_HOME}/Programs/3.6.6-117.tar.gz
cd ASF_MapReady-3.6.6-117
./configure --prefix=${OSK_HOME}/Programs/ASF_bin
make
make install

# PolSARPro
mkdir -p ${OSK_HOME}/Programs/PolSARPro504
cd ${OSK_HOME}/Programs/PolSARPro504
wget https://earth.esa.int/documents/653194/1960708/PolSARpro_v5.0.4_Linux_20150607

unrar x PolSARpro_v5.0.4_Linux_20150607
cd Soft
bash Compil_PolSARpro_v5_Linux.bat 

# SNAP
mkdir -p ${OSK_HOME}/Programs/
wget http://sentinel1.s3.amazonaws.com/1.0/s1tbx_1.1.1_Linux64_installer.sh
sh s1tbx_1.1.1_Linux64_installer.sh -q -overwrite

# Update global environment variables
cp ${OSK_HOME}/OpenSARKit/OpenSARKit_source.bash /etc/profile.d/OpenSARKit.sh

chmod -R 755 ${OSK_HOME}

#------------------------------------------------------------------
# 3 Download the additional Database
#------------------------------------------------------------------

mkdir -p ${OSK_HOME}/Database
cd ${OSK_HOME}/Database
wget https://www.dropbox.com/s/58cnjj8xymzkbac/global_info.sqlite?dl=0

echo "---------------------------"
echo "Installation of OFSK completed"
echo "---------------------------"
