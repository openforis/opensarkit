#! /bin/bash

# Support script to source the original programs
export OSK_HOME=/usr/local/lib/osk
# Folder of OpenSARKit scripts and workflows
export OPENSARKIT="${OSK_HOME}/OpenSARKit"

#versionin etc
export OSK_VERSION=0.1-beta

export AUTHOR_1="Andreas Vollrath"
export CONTACT_1="andreas.vollrath@fao.org"

export AUTHOR_2=""

# Folder of external program installations
PROGRAMS="${OPENSARKIT}/Programs"

# source auxiliary Spatialite database
export DB_GLOBAL=${OPENSARKIT}/Database/global_info.sqlite	 

# source lib-functions
source ${OPENSARKIT}/lib/gdal_helpers
source ${OPENSARKIT}/lib/saga_helpers
source ${OPENSARKIT}/lib/s1_helpers

# PATHS
export SNAP="/home/avollrath/snap"
export SNAP_EXE="${SNAP}/bin/gpt"
export POLSAR="${PROGRAMS}/PolSARPro504/Soft"
export POLSAR_BIN=${POLSAR}/data_import:${POLSAR}/data_convert:${POLSAR}/speckle_filter:${POLSAR}/bmp_process:${POLSAR}/tools
export ASF_EXE="${PROGRAMS}/ASF_bin/bin"

# source worklows/graphs
export NEST_GRAPHS="${OPENSARKIT}/workflows/NEST"
export SNAP_GRAPHS="${OPENSARKIT}/workflows/SNAP"
export ASF_CONF="${OPENSARKIT}/workflows/ASF"
export POLSAR_CONF="${OPENSARKIT}/workflows/POLSAR"

# source worklows/graphs
export NEST_BIN="${OPENSARKIT}/bins/NEST"
export SNAP_BIN="${OPENSARKIT}/bins/SNAP"
export ASF_BIN="${OPENSARKIT}/bins/ASF"
export DOWNLOAD_BIN="${OPENSARKIT}/bins/Download"
export PYTHON_BIN="${OPENSARKIT}/python"
export GDAL_BIN="${OPENSARKIT}/bins/GDAL"
export SAGA_BIN="${OPENSARKIT}/bins/SAGA"
export RSGISLIB_BIN="${OPENSARKIT}/bins/RSGISLIB"

# export to Path
export PATH=$PATH:${PYTHON_BIN}:${RSGISLIB_BIN}:${ASF_BIN}:${POLSAR_BIN}:${SAGA_BIN}:${SNAP_BIN}:${NEST_BIN}:${GDAL_BIN}:${DOWNLOAD_BIN}:${ASF_EXE}:${SNAP}



