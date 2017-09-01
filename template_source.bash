#! /bin/bash

#-------------------------------------------------------
export OPENSARKIT="change me"

# path to snap installation folder
export SNAP="change me"
export SNAP_EXE="${SNAP}/bin/gpt"

# Folder of OFST database
# 1.) download the database here: https://www.dropbox.com/s/qvujm3l0ba0frch/OFST_db.sqlite
# 2.) place somewhere
# e.g. if placed into ${OPENSARKIT}/Database folder it should look like this:
# export DB_GLOBAL="${OPENSARKIT}/Database/OFST_db.sqlite"
export DB_GLOBAL="change me"

#-------------------------------------------------------
# this does not have to be changed
# versionin etc
export OSK_VERSION=0.1-beta

# source worklows/graphs
export SNAP_GRAPHS="${OPENSARKIT}/workflows/SNAP"

# source bins
export SNAP_BIN="${OPENSARKIT}/bins/SNAP"
export ASF_BIN="${OPENSARKIT}/bins/ASF"
export KC_BIN="${OPENSARKIT}/bins/KC"
export DOWNLOAD_BIN="${OPENSARKIT}/bins/Download"

# export to Path
export PATH=$PATH:${PYTHON_BIN}:${ASF_BIN}:${SNAP_BIN}:${GDAL_BIN}:${DOWNLOAD_BIN}:${ASF_EXE}:${SNAP}:${KC_BIN}:${REMOTE_BIN}:${SAGA_BIN}:${POLSAR_BIN}:${NEST_BIN}
#----------------------------------------------------------


