#! /bin/bash

# Support script to source the original programs

# Folder of external program installations
PROGRAMS="/usr/programs"
export NEST_EXE=${PROGRAMS}/NEST/gpt.sh
export S1TBX_EXE=${PROGRAMS}/S1TBX/gpt.sh
export POLSAR="/usr/programs/PolSARPro/Soft"
export POLSAR_BIN=${POLSAR}/data_import:${POLSAR}/data_convert:${POLSAR}/speckle_filter:${POLSAR}/bmp_process:${POLSAR}/tools
# ASF Mapready
# GMTSAR
# DORIS 

# Folder of OpenSARKit scripts and workflows
export OPENSARKIT="/home/avollrath/github/OpenSARKit"

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


export PATH=$PATH:${PYTHON_BIN}:${RSGISLIB_BIN}:${ASF_BIN}:${POLSAR_BIN}

# Aliases

# Downloads
alias osk_download_ALOS_ASF="bash ${DOWNLOAD_BIN}/osk_download_ALOS_ASF.sh"

# Imports
alias osk_ALOS_CEOS_import="bash ${NEST_BIN}/osk_import_ALOS_L1_1_CEOS_to_dim.sh"

# Process
alias osk_single_ALOS_preprocess="bash ${S1TBX_BIN}/osk_ALOS_L1_1_preprocess_SS.sh"
alias osk_single_ALOS_preprocess_nest="bash ${S1TBX_BIN}/osk_ALOS_L1_1_preprocess_SS_nest.sh"
alias osk_path_ALOS_preprocess="bash ${S1TBX_BIN}/osk_ALOS_L1_1_preprocess.sh"
alias osk_mosaic_ALOS_preprocess="bash ${S1TBX_BIN}/osk_bulk_ALOS_L1_1_preprocess.sh"
alias osk_ALOS_merge_path="bash ${S1TBX_BIN}/osk_ALOS_merge_path.sh"

alias osk_ALOS_preprocess_ASF="bash ${ASF_BIN}/osk_ALOS_L1_1_preprocess_asf.sh"
alias osk_single_ALOS_L1.5_preprocess_asf="bash ${ASF_BIN}/osk_single_ALOS_L1.5_preprocess_asf.sh"
alias osk_path_ALOS_L1.5_preprocess_asf="bash ${ASF_BIN}/osk_path_ALOS_L1.5_preprocess_asf.sh"

# Postprocess
alias osk_postprocess="bash ${SAGA_BIN}/osk_postprocess.sh"


