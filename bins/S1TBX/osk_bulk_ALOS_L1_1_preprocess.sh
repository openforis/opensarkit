#! /bin/bash


# TMP sourcing for Sepal env.
source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------

# 	0.1 Check for right usage
if [ "$#" != "2" ]; then
  echo -e "Usage: osk_bulk_ALOS_L1_1_preprocess /path/to/downloaded/satellite/tracks /path/to/dem"
  echo -e "The path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Processing folder: ${PROC_DIR}"
fi
source /home/avollrath/github/OpenSARKit/OpenSARKit_source.bash
#----------------------------------------------------------------------
#	1 Do the bulk!
#----------------------------------------------------------------------

cd ${PROC_DIR}
for SAR_TRACK in `ls -1 -d [0-9]*`;do

	echo "------------------------------------------------"
	echo " Bulk Processing ALOS FBD: Track: ${SAR_TRACK}"
	echo "------------------------------------------------"

	bash ${S1TBX_BIN}/osk_ALOS_L1_1_preprocess_nest.sh ${PROC_DIR}/${SAR_TRACK} $2  

done
