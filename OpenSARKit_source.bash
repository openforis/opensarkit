#! /bin/bash

# Support script to source the original programs

# Folder of external program installations
PROGRAMS="/usr/programs"
export NEST_EXE=${PROGRAMS}/NEST/gpt.sh
export S1TBX_EXE=${PROGRAMS}/S1TBX/gpt.sh
# ASF Mapready
# GMTSAR
# DORIS 

# Folder of OpenSARKit scripts and workflows
export OPENSARKIT="/home/avollrath/github/OpenSARKit"

# source worklows/graphs
export NEST_GRAPHS="${OPENSARKIT}/workflows/NEST"
export S1TBX_GRAPHS="${OPENSARKIT}/workflows/S1TBX"

# source worklows/graphs
export NEST_BIN="${OPENSARKIT}/bins/NEST"
export S1TBX_BIN="${OPENSARKIT}/bins/S1TBX"
export DOWNLOAD_BIN="${OPENSARKIT}/download_scripts"
export PYTHON_BIN="${OPENSARKIT}/python"
export GDAL_BIN="${OPENSARKIT}/bins/GDAL"

export PATH=$PATH:${PYTHON_BIN}

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


# Helpers
#alias osk_byteswap_float32="python ${PYTHON_BIN}/osk_byteswap32.py"

