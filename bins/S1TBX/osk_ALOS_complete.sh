#! /bin/bash

WORKSPACE=/data/home/Andreas.Vollrath/datasets/Sri_Lanka/FBD

source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash
cd $WORKSPACE

for JAHR in `ls -1`; do

	cd $WORKSPACE
	bash /data/home/Andreas.Vollrath/github/OpenSARKit/bins/S1TBX/osk_bulk_ALOS_L1_1_preprocess.sh $WORKSPACE/$JAHR /data/home/Andreas.Vollrath/datasets/Sri_Lanka/DEM/Sri_Lanka_SRTM1_filled.tif

	bash /data/home/Andreas.Vollrath/github/OpenSARKit/bins/S1TBX/osk_ALOS_merge_path.sh $WORKSPACE/$JAHR

done
