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
source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash

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

#	loop for every scene
for FILE in `ls -1 ${ZIP_DIR}`;do

	cd ${ZIP_DIR}
	# Extract file
	echo "Extracting ${FILE}"
	unzip -o -q ${FILE} -d ${TMP_DIR}

	# extract filenames
	SCENE_ID=`ls ${TMP_DIR}`
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
	echo "Acquisiton Mode:			${MODE}"
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
	OUTPUT_DIMAP=${FINAL_DIR}/${SCENE_ID}.dim

	# Write new xml graph and substitute input and output files
	cp ${NEST_GRAPHS}/ALOS_L1.1_NEST_import.xml ${TMP_DIR}/Import_DIMAP.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_RAW|${INPUT_RAW}|g" ${TMP_DIR}/Import_DIMAP.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_DIMAP|${OUTPUT_DIMAP}|g" ${TMP_DIR}/Import_DIMAP.xml

	echo "Importing CEOS files to BEAM_DIMAP file format for ${SCENE_ID} from $DATE"
	sh ${NEST_EXE} ${TMP_DIR}/Import_DIMAP.xml 2>&1 | tee ${TMP_DIR}/tmplog
	EXIT_CODE=$?

	echo $EXIT_CODE

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog;then 
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}".dim" ${FINAL_DIR}/${SCENE_ID}".data"
		sh ${NEST_EXE} ${TMP_DIR}/Import_DIMAP.xml  
	fi



#----------------------------------------------------------------------
# 	2 Create multilooked, Lee speckle-filtered intensities
#----------------------------------------------------------------------	

	
	# define output
	OUTPUT_ML_SPK=${TMP_DIR}/${SCENE_ID}"_ML_SPK.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_DSK_ML_SPK.xml ${TMP_DIR}/ML_SPK.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_DIMAP|${OUTPUT_DIMAP}|g" ${TMP_DIR}/ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_ML_SPK|${OUTPUT_ML_SPK}|g" ${TMP_DIR}/ML_SPK.xml

	echo "Apply Multi-look & Speckle Filter to ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK.data"
		sh ${S1TBX_EXE} ${TMP_DIR}/ML_SPK.xml 
	fi

	# Geocode Multi-looked, speckle-filtered imagery

	OUTPUT_ML_SPK_TR=${FINAL_DIR}/${SCENE_ID}'_ML_SPK_TR.dim'
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_radiometric.xml ${TMP_DIR}/TR_ML_SPK.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_ML_SPK}|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_ML_SPK_TR}|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert DEM path
	sed -i "s|DEM_FILE|${DEM_FILE}|g" ${TMP_DIR}/TR_ML_SPK.xml

	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Multi-looked, speckle-filtered scene: ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${FINAL_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml 
	fi
	
#----------------------------------------------------------------------
# 	3 Create Speckle Divergence files
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_SPK_DIV=${TMP_DIR}/${SCENE_ID}"_SPK_DIV.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_DSK_SPK-DIV_ML.xml ${TMP_DIR}/SPK_DIV.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_DIMAP|${OUTPUT_DIMAP}|g" ${TMP_DIR}/SPK_DIV.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_SPK_DIV|${OUTPUT_SPK_DIV}|g" ${TMP_DIR}/SPK_DIV.xml

	echo "Calculate Speckle Divergence and apply Multi-looking for ${SCENE_ID}"
#	sh ${S1TBX_EXE} ${TMP_DIR}/SPK_DIV.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_SPK_DIV.dim" ${TMP_DIR}/${SCENE_ID}"_SPK_DIV.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/SPK_DIV.xml
	fi
	
	# Geocode Speckle-Divergence

	# define output file name
	OUTPUT_SPK_DIV_TR=${FINAL_DIR}/${SCENE_ID}'_SPK_DIV_TR.dim'
	# copy template xml graph into tmp folder 
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_SPK_DIV.xml ${TMP_DIR}/TR_SPK_DIV.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_SPK_DIV}|g" ${TMP_DIR}/TR_SPK_DIV.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_SPK_DIV_TR}|g" ${TMP_DIR}/TR_SPK_DIV.xml
	# insert external DEM path
	sed -i "s|DEM_FILE|${DEM_FILE}|g" ${TMP_DIR}/TR_SPK_DIV.xml

	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Speckle-Divergence from scene: ${SCENE_ID}"
#	sh ${S1TBX_EXE} ${TMP_DIR}/TR_SPK_DIV.xml 2>&1  | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_SPK_DIV_TR.dim" ${FINAL_DIR}/${SCENE_ID}"_SPK_DIV_TR.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/TR_SPK_DIV.xml
	fi

#----------------------------------------------------------------------
# 	4 Create Polarimetric Products
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_POLSAR=${TMP_DIR}/${SCENE_ID}"_H_alpha.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_H_alpha.xml ${TMP_DIR}/POLSAR.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_DIMAP|${OUTPUT_DIMAP}|g" ${TMP_DIR}/POLSAR.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_POLSAR|${OUTPUT_POLSAR}|g" ${TMP_DIR}/POLSAR.xml

	echo "Calculate H-alpha dual pol decomposition for ${SCENE_ID}"
#	sh ${S1TBX_EXE} ${TMP_DIR}/POLSAR.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_H_alpha.dim" ${TMP_DIR}/${SCENE_ID}"_H_alpha.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/POLSAR.xml
	fi

	# 5c	Multi-look & Geocode Polsar H-alpha dual pol data (multilook included, since it does not work for the preproc chain)

	# define output file name
	OUTPUT_POLSAR_TR=${FINAL_DIR}/${SCENE_ID}'_H_alpha_TR.dim'
	# copy template xml graph into tmp folder
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_ML_H_alpha.xml ${TMP_DIR}/TR_H_alpha.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_POLSAR}|g" ${TMP_DIR}/TR_H_alpha.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_POLSAR_TR}|g" ${TMP_DIR}/TR_H_alpha.xml
	# insert external DEM path
	sed -i "s|DEM_FILE|${DEM_FILE}|g" ${TMP_DIR}/TR_H_alpha.xml

	# Radiometrically terrain correcting PolSAR H-A-alpha products
	echo "Geocode H-A-alpha from scene: ${SCENE_ID}"
#	sh ${S1TBX_EXE} ${TMP_DIR}/TR_H_alpha.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_H_alpha_TR.dim" ${FINAL_DIR}/${SCENE_ID}"_H_alpha_TR.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/TR_H_alpha.xml
	fi

#----------------------------------------------------------------------
# 	5 HH/HV ratio
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_RATIO=${FINAL_DIR}/${SCENE_ID}"_HHHV_ratio.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_HHHV_ratio.xml ${TMP_DIR}/RATIO.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_ML_SPK_TR}|g" ${TMP_DIR}/RATIO.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_RATIO}|g" ${TMP_DIR}/RATIO.xml

	echo "Calculating HV/HH ratio ${SCENE_ID}"
	sh ${NEST_EXE} ${TMP_DIR}/RATIO.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_HHHV_ratio.dim" ${FINAL_DIR}/${SCENE_ID}"_HHHV_ratio.data"
		sh ${NEST_EXE} ${TMP_DIR}/RATIO.xml
	fi
#----------------------------------------------------------------------
# 	6 Texture
#----------------------------------------------------------------------	

	# HH texture calculations

	# define path/name of output
	OUTPUT_TEXTURE_HH=${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HH.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_Texture_HH.xml ${TMP_DIR}/TEXTURE_HH.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_ML_SPK_TR}|g" ${TMP_DIR}/TEXTURE_HH.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_TEXTURE_HH}|g" ${TMP_DIR}/TEXTURE_HH.xml

	echo "Calculate GLCM Texture measurements for HH channel"
#	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HH.dim" ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HH.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml
	fi

	# HV texture calculations

	# define path/name of output
	OUTPUT_TEXTURE_HV=${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HV.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_Texture_HV.xml ${TMP_DIR}/TEXTURE_HV.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_ML_SPK_TR}|g" ${TMP_DIR}/TEXTURE_HV.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_TEXTURE_HV}|g" ${TMP_DIR}/TEXTURE_HV.xml

	echo "Calculate GLCM Texture measurements for HV channel"
#	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HV.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HV.dim" ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HV.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HV.xml
	fi

#----------------------------------------------------------------------
# 	7 Layover/Shadow Mask
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_LAYOVER=${TMP_DIR}/${SCENE_ID}"_LAYOVER.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_Layover.xml ${TMP_DIR}/LAYOVER.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_DIMAP|${OUTPUT_DIMAP}|g" ${TMP_DIR}/LAYOVER.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_LAYOVER|${OUTPUT_LAYOVER}|g" ${TMP_DIR}/LAYOVER.xml
	# insert external DEM path
	sed -i "s|DEM_FILE|${DEM_FILE}|g" ${TMP_DIR}/LAYOVER.xml

	echo "Calculate the Layover/Shadow mask"
#	sh ${S1TBX_EXE} ${TMP_DIR}/LAYOVER.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_LAYOVER.dim" ${TMP_DIR}/${SCENE_ID}"_LAYOVER.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/LAYOVER.xml
	fi

	# Geocode Layover
	OUTPUT_LAYOVER_TR=${FINAL_DIR}/${SCENE_ID}'_LAYOVER_TR.dim'
	# copy template xml graph into tmp folder 
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_Layover.xml ${TMP_DIR}/TR_LAYOVER.xml

	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_LAYOVER}|g" ${TMP_DIR}/TR_LAYOVER.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_LAYOVER_TR}|g" ${TMP_DIR}/TR_LAYOVER.xml
	# insert external DEM path
	sed -i "s|DEM_FILE|${DEM_FILE}|g" ${TMP_DIR}/TR_LAYOVER.xml

	# Terrain correcting Layover mask
	echo "Geocode Layover/Shadow Mask: ${SCENE_ID}"
#	sh ${S1TBX_EXE} ${TMP_DIR}/TR_LAYOVER.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_LAYOVER_TR.dim" ${FINAL_DIR}/${SCENE_ID}"_LAYOVER_TR.data"
#		sh ${S1TBX_EXE} ${TMP_DIR}/TR_LAYOVER.xml
	fi
#----------------------------------------------------------------------
# 	8 Remove tmp files
#----------------------------------------------------------------------	

	rm -rf ${TMP_DIR}/*
done

rm -rf ${TMP_DIR}
