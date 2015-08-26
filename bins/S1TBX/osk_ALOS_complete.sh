#! /bin/bash

#WORKSPACE=/data/home/Andreas.Vollrath/datasets/Sri_Lanka/FBD
WORKSPACE=/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/FBD

source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash
cd $WORKSPACE

for JAHR in `ls -1`; do

	cd $WORKSPACE
	echo "bash /home/avollrath/github/OpenSARKit/bins/S1TBX/osk_bulk_ALOS_L1_1_preprocess.sh $WORKSPACE/$JAHR /media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/SRTM1/Sri_Lanka_SRTM1_filled.tif"
	bash /home/avollrath/github/OpenSARKit/bins/S1TBX/osk_bulk_ALOS_L1_1_preprocess.sh $WORKSPACE/$JAHR /media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/SRTM1/Sri_Lanka_SRTM1_filled.tif
#	bash /data/home/Andreas.Vollrath/github/OpenSARKit/bins/S1TBX/osk_bulk_ALOS_L1_1_preprocess.sh $WORKSPACE/$JAHR /data/home/Andreas.Vollrath/datasets/Sri_Lanka/DEM/Sri_Lanka_SRTM1_filled.tif

	echo "bash /home/avollrath/github/OpenSARKit/bins/S1TBX/osk_ALOS_merge_path.sh $WORKSPACE/$JAHR"
	bash /home/avollrath/github/OpenSARKit/bins/S1TBX/osk_ALOS_merge_path.sh $WORKSPACE/$JAHR
	#bash /data/home/Andreas.Vollrath/github/OpenSARKit/bins/S1TBX/osk_ALOS_merge_path.sh $WORKSPACE/$JAHR
done
