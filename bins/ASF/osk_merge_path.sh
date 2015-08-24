#! /bin/bash

# dependecies
#	SAGA GIS (Version > 2.1.4)
#  dans-gdal-scripts
#  gdal-libs

# TMP sourcing for Sepal env.
source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------

# 	0.1 Check for right usage
if [ "$#" != "1" ]; then
  echo -e "Usage: osk_ALOS_merge_path /path/to/satellite/tracks"
  echo -e "The path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Processing folder: ${PROC_DIR}"
fi

# Number of CPUs (for SAGA GIS)
CPU=`lscpu | grep "CPU(s):" | awk $'{print $2}' | head -1`

# Path structure
cd ${PROC_DIR}
TMP_DIR=${PROC_DIR}/TMP
mkdir -p ${TMP_DIR}
mkdir -p ${PROC_DIR}/PATH
mkdir -p ${PROC_DIR}/PATH/MOSAICS
mkdir -p ${PROC_DIR}/PATH/KMZS
mkdir -p ${PROC_DIR}/PATH/OUTLINES

# Loop for Acquisition Date
for ACQ_DATE in `ls -1 -d [1,2]*`;do 

	cd ${ACQ_DATE}

	# Loop for Frames
	for FRAME in `ls -1 -d [0-9]*`;do 
		

		cd $FRAME
		ORBIT=${FRAME:5:10}
	
		echo "Translate to SAGA GIS format (powerful and fast raster manipulation)"				
		gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -t_srs EPSG:4326 -tr 0.000138889 0.000138889 -overwrite -of SAGA -srcnodata "0" -dstnodata "-99999" Gamma0_HH.tif ${TMP_DIR}/${FRAME}"_Gamma0_HH_saga.sdat"
		gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -t_srs EPSG:4326 -tr 0.000138889 0.000138889 -overwrite -of SAGA -srcnodata "0" -dstnodata "-99999" Gamma0_HV.tif ${TMP_DIR}/${FRAME}"_Gamma0_HV_saga.sdat"
	
		echo ${TMP_DIR}/${FRAME}"_Gamma0_HH_saga.sgrd" >> ${TMP_DIR}/Gamma0_HH_db_list
		echo ${TMP_DIR}/${FRAME}"_Gamma0_HV_saga.sgrd" >> ${TMP_DIR}/Gamma0_HV_db_list
	
		cd ../
	
	done

	LIST_HH=`cat ${TMP_DIR}/Gamma0_HH_db_list | tr '\n' ';' | rev | cut -c 2- | rev`
	saga_cmd -c=${CPU} grid_tools 3 -GRIDS:"${LIST_HH}" -TYPE:7 -OVERLAP:4 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH/MOSAICS/${ACQ_DATE}"_Gamma0_HH_"${ORBIT}.sgrd

	LIST_HV=`cat ${TMP_DIR}/Gamma0_HV_db_list | tr '\n' ';' | rev | cut -c 2- | rev`
	saga_cmd -c=${CPU} grid_tools 3 -GRIDS:"${LIST_HV}" -TYPE:7 -OVERLAP:4 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH/MOSAICS/${ACQ_DATE}"_Gamma0_HV_"${ORBIT}.sgrd
	
	echo "creating a shapefile for all valid points"
	gdal_trace_outline ${ACQ_DATE}"_Gamma0_HV_"${ORBIT}.sdat -ndv -99999 -dp-toler 0 -out-cs en -ogr-out ${PROC_DIR}/PATH/OUTLINES/${ACQ_DATE}"_Gamma0_HV_"${ORBIT}.shp
	echo "creating a KMZ file for GoogleEarth"
	gdal_translate -of KMLSUPEROVERLAY -a_nodata 0 -outsize 25% 25% -scale 0.001 0.1 0 255 ${PROC_DIR}/PATH/MOSAICS/${ACQ_DATE}"_Gamma0_HV_"${ORBIT}.sdat  ${PROC_DIR}/PATH/KMZS/${ACQ_DATE}"_Gamma0_HV_"${ORBIT}.kmz -co FORMAT=PNG

	rm -rf ${TMP_DIR}/*
	cd ${PROC_DIR}
	
done

cd ${PROC_DIR}

tar -cfzv ${PROC_DIR}/PATH/OUTLINES
tar -cfzv ${PROC_DIR}/PATH/KMZS
rm -rf ${TMP_DIR}


