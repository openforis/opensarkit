#! /bin/bash

# Kealib
#apt-get install --yes mercurial git build-essential cmake-curses-gui

echo "edit GDAL INCLUDE PATH to /usr/include/gdal"
echo "edit GDAL LIB PATH to /usr/lib"
echo "edit HDF5 INCLUDE PATH to /usr/include/"
echo "edit HDF5 INCLUDE PATH to /usr/lib/"

cd /usr/local/src
#hg clone https://bitbucket.org/chchrsc/kealib
cd kealib/trunk
#ccmake .

#make
#make install

#echo "export GDAL_DRIVER_PATH=/usr/local/gdalplugins" >> ~/.bashrc

# RSGISLib

#apt-get install --yes libcgal-dev

cd /usr/local/src
hg clone https://bitbucket.org/petebunting/rsgislib rsgislib

cd rsgislib/src

cmake -D CMAKE_INSTALL_PREFIX=/usr/local/lib \
-D BOOST_INCLUDE_DIR=/usr/include/boost \
-D BOOST_LIB_PATH=/usr/lib/x86_64-linux-gnu \
-D GDAL_INCLUDE_DIR=/usr/include/gdal \
-D GDAL_LIB_PATH=/usr/lib \
-D HDF5_INCLUDE_DIR=/usr/include/ \
-D HDF5_LIB_PATH=/usr/lib/x86_64-linux-gnu \
-D XERCESC_INCLUDE_DIR=/usr/include/xercesc \
-D XERCESC_LIB_PATH=/usr/lib \
-D GSL_INCLUDE_DIR=/usr/include/gsl \
-D GSL_LIB_PATH=/usr/lib \
-D FFTW_INCLUDE_DIR=/usr/include/ \
-D FFTW_LIB_PATH=/usr/lib/x86_64-linux-gnu \
-D GEOS_INCLUDE_DIR=/usr/include/geos \
-D GEOS_LIB_PATH=/usr/local \
-D MUPARSER_INCLUDE_DIR=/usr/include \
-D MUPARSER_LIB_PATH=/usr/lib/x86_64-linux-gnu \
-D CGAL_INCLUDE_DIR=/usr/include/CGAL \
-D CGAL_LIB_PATH=/usr/lib \
-D GMP_INCLUDE_DIR=/usr/include/x86_64-linux-gnu \
-D GMP_LIB_PATH=/usr/lib/x86_64-linux-gnu \
-D MPFR_INCLUDE_DIR=/usr/include \
-D MPFR_LIB_PATH=/usr/lib/x86_64-linux-gnu \
-D KEA_INCLUDE_DIR=/usr/local/include/libkea \
-D KEA_LIB_PATH=/usr/local/lib \
-D CMAKE_VERBOSE_MAKEFILE=ON \
.

make
make install
