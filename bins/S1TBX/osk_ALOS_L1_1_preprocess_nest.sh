#!/bin/bash


#----------------------------------------------------------------------
#	ALOS Level 1.1 FBD DualPol-SAR/Backscatter/Texture Processing
#
#	Dependencies:
#
#		- NEST Toolbox
#		- Sentinel 1 Toolbox
#
#
#----------------------------------------------------------------------

# TMP sourcing for Sepal env.
#source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash
source /home/avollrath/github/OpenSARKit/OpenSARKit_source.bash

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------
	
# 	0.1 Check for right usage
if [ "$#" != "2" ]; then
  echo -e "Usage: osk_ALOS_L1_1_preprocess /path/to/downloaded/zips /path/to/dem"
  echo -e "The path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Processing folder: ${PROC_DIR}"
fi


#DEM_FILE='/home/avollrath/test/final_dem_filled.tif'
DEM_FILE=$2

#	0.2 Define Workspace
export TMP_DIR="${PROC_DIR}/TMP"
export ZIP_DIR="${PROC_DIR}/ZIP"

#	0.3 Create Workspace
mkdir -p ${ZIP_DIR}
mkdir -p ${TMP_DIR}


#----------------------------------------------------------------------
# 	1 Import Raw data to DIMAP format compatible with S1TBX
#----------------------------------------------------------------------

# 	move data 
mv ${PROC_DIR}/*zip ${ZIP_DIR}

# set number for session refNo
i=1
#	loop for every scene
for FILE in `ls -1 ${ZIP_DIR}`;do

	cd ${ZIP_DIR}
	# Extract file
	echo "Extracting ${FILE}"
	unzip -o -q ${FILE} -d ${TMP_DIR}

	# extract filenames
	SCENE_ID=`ls ${TMP_DIR}`
	#SCENE_ID=ALPSRP073760140-L1.1
	cd ${TMP_DIR}/${SCENE_ID}
	VOLUME_FILE=`ls VOL*`

	# check for mode
	if grep -q IMG-VV workreport;then

		MODE="PLR"

	elif grep -q IMG-HV workreport;then

		MODE="FBD"
	
	else

		MODE="FBS"
	fi

	# extract Date and Footprint
	YEAR=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 2-5`
	MONTH=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 6-7`
	DAY=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 7-8`
	DATE=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 2-9`

#	UL_LAT=`cat workreport | grep Brs_ImageSceneLeftTopLatitude | awk -F "=" $'{print $2}' | sed 's/\"//g'`
#	UL_LAT=`cat workreport | grep Brs_ImageSceneLeftTopLatitude | awk -F "=" $'{print $2}' | sed 's/\"//g'`
	
	FRAME=`echo ${SCENE_ID}	| cut -c 12-15`	
	# !!!!!needs change for final version!!!!!	
	SAT_PATH=`curl -s http://api.daac.asf.alaska.edu/services/search/param?keyword=value\&granule_list=${SCENE_ID:0:15}\&output=csv | tail -n 1 | awk -F "," $'{print $7}' | sed 's/\"//g'`
	
	echo "----------------------------------------------------------------"
	echo "Processing Scene: 		${SCENE_ID:0:15}"
	echo "Satellite/Sensor: 		ALOS/Palsar"
	echo "Acquisiton Mode:		${MODE}"
	echo "Acquisition Date (YYYYMMDD):	${DATE}"
	echo "Relative Satellite Track: 	${SAT_PATH}"
	echo "Image Frame: 			$FRAME"
	echo "----------------------------------------------------------------"

	mkdir -p ${PROC_DIR}/${DATE}
	mkdir -p ${PROC_DIR}/${DATE}/${FRAME}

	FINAL_DIR=${PROC_DIR}/${DATE}/${FRAME}

#----------------------------------------------------------------------
# 	1 Import Raw data to DIMAP format compatible with S1TBX
#----------------------------------------------------------------------

	# define input/output
	INPUT_RAW=${TMP_DIR}/${SCENE_ID}/${VOLUME_FILE}	
	OUTPUT_DIMAP=${TMP_DIR}/${SCENE_ID}.dim

	echo "Importing CEOS files to BEAM_DIMAP file format for ${SCENE_ID} from $DATE"
	sh ${NEST_EXE} ${NEST_GRAPHS}/ALOS_L1.1_NEST_import.xml ${INPUT_RAW} -t ${OUTPUT_DIMAP} 2>&1 | tee ${TMP_DIR}/tmplog
#	[ $? -ne 0 ] && return ${ERR_IMPORT}

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog;then 
		echo "2nd try"
		rm -rf ${TMP_DIR}/${SCENE_ID}".dim" ${TMP_DIR}/${SCENE_ID}".data"
		sh ${NEST_EXE} ${NEST_GRAPHS}/ALOS_L1.1_NEST_import.xml ${INPUT_RAW} -t ${OUTPUT_DIMAP} 2>&1 | tee ${TMP_DIR}/tmplog
	fi


#----------------------------------------------------------------------
# 	2 Create multilooked, Lee speckle-filtered intensities
#----------------------------------------------------------------------	

	
	# define output
	OUTPUT_ML_SPK=${TMP_DIR}/${SCENE_ID}"_ML_SPK.dim"

	echo "Apply Multi-look & Speckle Filter to ${SCENE_ID}"
	sh ${NEST_EXE} ${NEST_GRAPHS}/ALOS_L1.1_DSK_ML_SPK.xml ${OUTPUT_DIMAP} -t ${OUTPUT_ML_SPK} 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK.data"
		sh ${NEST_EXE} ${NEST_GRAPHS}/ALOS_L1.1_DSK_ML_SPK.xml ${OUTPUT_DIMAP} -t ${OUTPUT_ML_SPK} 2>&1 | tee  ${TMP_DIR}/tmplog
	fi


#----------------------------------------------------------------------
# 	3 Geocoding with Radiometric normalization
#----------------------------------------------------------------------	

	OUTPUT_ML_SPK_TR=${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim"
	OUTPUT_GAMMA_HH=${TMP_DIR}/${SCENE_ID}'_Gamma0_HH.dim'
	OUTPUT_GAMMA_HV=${TMP_DIR}/${SCENE_ID}'_Gamma0_HV.dim'
	OUTPUT_LAYOVER=${TMP_DIR}/${SCENE_ID}'_Layover_Shadow.dim'

	# NEST version
	cp ${NEST_GRAPHS}/ALOS_L1.1_SIMTR2.xml ${TMP_DIR}/TR_ML_SPK.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_ML_SPK}|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_ML_SPK_TR}|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_HH|${OUTPUT_GAMMA_HH}|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_HV|${OUTPUT_GAMMA_HV}|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_LAY|${OUTPUT_LAYOVER}|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert DEM path
	sed -i "s|DEM_FILE|${DEM_FILE}|g" ${TMP_DIR}/TR_ML_SPK.xml

	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Multi-looked, speckle-filtered scene: ${SCENE_ID}"
	# Nest	
	sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
	
	# in case it fails try a another time	
	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 2nd time, since coarse offset did not found GCPs"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
		sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
	fi

	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 3rd time, since coarse offset did not start (NEST bug)"
		echo "This time we will take 4000 GCPs, but smaller windows size (probably too much water in the scene)"
		sed -i "s|<numGCPtoGenerate>500|<numGCPtoGenerate>8000|g" ${TMP_DIR}/TR_ML_SPK.xml
		sed -i "s|<coarseRegistrationWindowWidth>128|<coarseRegistrationWindowWidth>64|g" ${TMP_DIR}/TR_ML_SPK.xml
		sed -i "s|<coarseRegistrationWindowHeight>256|<coarseRegistrationWindowHeight>64|g" ${TMP_DIR}/TR_ML_SPK.xml
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
		sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
	fi

	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 4th time, since coarse offset did not start (NEST bug)"
		echo "This time we will take also increase the window size for the coarse registration to 1024/512 (height/width)"
		sed -i "s|<coarseRegistrationWindowWidth>64|<coarseRegistrationWindowWidth>512|g" ${TMP_DIR}/TR_ML_SPK.xml
		sed -i "s|<coarseRegistrationWindowHeight>64|<coarseRegistrationWindowHeight>1024|g" ${TMP_DIR}/TR_ML_SPK.xml
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
		sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
	fi

	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 5th time, since coarse offset did not start (NEST bug)"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${TMP_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
		sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 

	fi
	

if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 

	echo "${SCENE_ID}" >> ${PROC_DIR}/../failed_scenes

else
	# exclude low backscatter pixel to eliminate border effect
	gdal_calc.py --overwrite -A ${TMP_DIR}/${SCENE_ID}'_Gamma0_HH.data/Gamma0_HH.img' --outfile=${TMP_DIR}/tmp_mask_border_hh.tif --calc="A*(A>=0.001)" --NoDataValue=0
	gdal_calc.py --overwrite -A ${TMP_DIR}/${SCENE_ID}'_Gamma0_HV.data/Gamma0_HV.img' --outfile=${TMP_DIR}/tmp_mask_border_hv.tif --calc="A*(A>=0.001)" --NoDataValue=0

	# Apply Layover/Shadow mask
	echo "Invert Layover/Shadow Mask"	
	gdal_calc.py -A ${TMP_DIR}/${SCENE_ID}'_Layover_Shadow.data/layover_shadow_mask.img' --outfile=${TMP_DIR}/mask.tif --calc="1*(A==0)" --NoDataValue=0

	echo "Multiply inverted Layover/Shadow mask wih image layers"
 	gdal_calc.py -A ${TMP_DIR}/mask.tif -B ${TMP_DIR}/tmp_mask_border_hh.tif --outfile=${TMP_DIR}/tmp_Gamma0_HH2.tif --calc="A*B" --NoDataValue=0
	gdal_calc.py -A ${TMP_DIR}/mask.tif -B ${TMP_DIR}/tmp_mask_border_hv.tif --outfile=${TMP_DIR}/tmp_Gamma0_HV2.tif --calc="A*B" --NoDataValue=0


	echo "fill holes "
	# translate to SAGA format
	gdalwarp -srcnodata 0 -dstnodata -99999 -of SAGA ${TMP_DIR}/tmp_Gamma0_HH2.tif ${TMP_DIR}/tmp_mask_hh_saga.sdat
	gdalwarp -srcnodata 0 -dstnodata -99999 -of SAGA ${TMP_DIR}/tmp_Gamma0_HV2.tif ${TMP_DIR}/tmp_mask_hv_saga.sdat

	# fill
	saga_cmd -f=r grid_tools 25 -GRID:${TMP_DIR}/tmp_mask_hh_saga.sgrd -MAXGAPCELLS:250 -MAXPOINTS:500 -LOCALPOINTS:25 -CLOSED:${TMP_DIR}/tmp_mask_hh_filled.sgrd
	saga_cmd -f=r grid_tools 25 -GRID:${TMP_DIR}/tmp_mask_hv_saga.sgrd -MAXGAPCELLS:250 -MAXPOINTS:500 -LOCALPOINTS:25 -CLOSED:${TMP_DIR}/tmp_mask_hv_filled.sgrd

	# retranslate to img
	gdalwarp -srcnodata -99999 -dstnodata 0 -of ENVI ${TMP_DIR}/tmp_mask_hh_filled.sdat ${TMP_DIR}/tmp_mask_hh_saga.img
	gdalwarp -srcnodata -99999 -dstnodata 0 -of ENVI ${TMP_DIR}/tmp_mask_hv_filled.sdat ${TMP_DIR}/tmp_mask_hv_saga.img
	
	echo "Byteswap the layers due to GDAL BIGENDIAN output of ENVI format"
	osk_byteswap32.py ${TMP_DIR}/tmp_mask_hh_saga.img ${TMP_DIR}/${SCENE_ID}'_Gamma0_HH.data/Gamma0_HH.img'
	osk_byteswap32.py ${TMP_DIR}/tmp_mask_hv_saga.img ${TMP_DIR}/${SCENE_ID}'_Gamma0_HV.data/Gamma0_HV.img'

#----------------------------------------------
#	4 Linear to dB output 
#----------------------------------------------

	# 4a) for Gamma0_HH band
	# define output file

	OUTPUT_GAMMA_HH_DB=${FINAL_DIR}/${SCENE_ID}'_GAMMA_HH_DB.dim'
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_lin_to_db.xml ${TMP_DIR}/GAMMA_HH_DB.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_GAMMA_HH}|g" ${TMP_DIR}/GAMMA_HH_DB.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_GAMMA_HH_DB}|g" ${TMP_DIR}/GAMMA_HH_DB.xml
	
	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Converting linear data to dB scale for Gamma0_HH"
	sh ${S1TBX_EXE} ${TMP_DIR}/GAMMA_HH_DB.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}'_GAMMA_HH_DB.dim' ${FINAL_DIR}/${SCENE_ID}'_GAMMA_HH_DB.data'
		sh ${S1TBX_EXE} ${TMP_DIR}/GAMMA_HH_DB.xml 
	fi

	# Linear to dB output Gamma_HH

	OUTPUT_GAMMA_HV_DB=${FINAL_DIR}/${SCENE_ID}'_GAMMA_HV_DB.dim'
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_lin_to_db.xml ${TMP_DIR}/GAMMA_HV_DB.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_GAMMA_HV}|g" ${TMP_DIR}/GAMMA_HV_DB.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_GAMMA_HV_DB}|g" ${TMP_DIR}/GAMMA_HV_DB.xml


	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Converting linear data to dB scale for Gamma0_HV"
	sh ${S1TBX_EXE} ${TMP_DIR}/GAMMA_HV_DB.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_GAMMA_HV_DB.dim" ${FINAL_DIR}/${SCENE_ID}"_GAMMA_HV_DB.data"
		sh ${S1TBX_EXE} ${TMP_DIR}/GAMMA_HV_DB.xml 
	fi


#----------------------------------------------------------------------
# 	6 Remove tmp files
#----------------------------------------------------------------------	

	rm -rf ${TMP_DIR}/*
done

rm -rf ${TMP_DIR}
