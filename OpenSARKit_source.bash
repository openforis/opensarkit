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
# Aliases
alias osk_ALOS_CEOS_import="bash ${NEST_BIN}/osk_import_ALOS_L1_1_CEOS_to_dim.sh"
alias osk_ALOS_FBD_L1.1_preprocess="bash ${S1TBX_BIN}/osk_ALOS_L1_1_preprocess.sh"
alias osk_download_ALOS_ASF="bash ${DOWNLOAD_BIN}/osk_download_ALOS_ASF.sh"
