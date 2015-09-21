#! /bin/bash

# Support script to source the original programs

# Folder of OpenSARKit scripts and workflows
export OPENSARKIT="${HOME}/github/OpenSARKit"

# Folder of external program installations
PROGRAMS="${OPENSARKIT}/Programs"

export S1TBX_EXE="${PROGRAMS}/S1TBX/gpt.sh"
export POLSAR="${PROGRAMS}/PolSARPro504"
export POLSAR_BIN=${POLSAR}/data_import:${POLSAR}/data_convert:${POLSAR}/speckle_filter:${POLSAR}/bmp_process:${POLSAR}/tools
export ASF_EXE="${PROGRAMS}/ASF_bin/bin"
# ASF Mapready
# GMTSAR
# DORIS 
#export NEST_EXE=${PROGRAMS}/NEST/gpt.sh

# source worklows/graphs
export NEST_GRAPHS="${OPENSARKIT}/workflows/NEST"
export S1TBX_GRAPHS="${OPENSARKIT}/workflows/S1TBX"
export ASF_CONF="${OPENSARKIT}/workflows/ASF"
export POLSAR_CONF="${OPENSARKIT}/workflows/POLSAR"

# source worklows/graphs
export NEST_BIN="${OPENSARKIT}/bins/NEST"
export S1TBX_BIN="${OPENSARKIT}/bins/S1TBX"
export ASF_BIN="${OPENSARKIT}/bins/ASF"
export DOWNLOAD_BIN="${OPENSARKIT}/download_scripts"
export PYTHON_BIN="${OPENSARKIT}/python"
export GDAL_BIN="${OPENSARKIT}/bins/GDAL"
export SAGA_BIN="${OPENSARKIT}/bins/SAGA"
export RSGISLIB_BIN="${OPENSARKIT}/bins/RSGISLIB"

export PATH=$PATH:${PYTHON_BIN}:${RSGISLIB_BIN}:${ASF_BIN}:${POLSAR_BIN}:${SAGA_BIN}:${S1TBX_BIN}:${NEST_BIN}:${GDAL_BIN}:${DOWNLOAD_BIN}:${ASF_EXE}

	# source database
export DB_GLOBAL=${OPENSARKIT}/DB/global_info.sqlite	 


