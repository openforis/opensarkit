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

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------

# 	0.1 Check for right usage
if [ "$#" != "1" ]; then
  echo -e "Usage: bash Import_ALOS_L.1_1_to_dim.sh /path/to/downloaded/zips"
  echo -e "The path will be your Project folder!"
  exit 1
else
  echo "Processing folder: 	$1"
  echo "OpenSARKit"
fi

#	0.2 Define Workspace
export PROC_DIR="$1"
export TMP_DIR="${PROC_DIR}/TMP"
export ZIP_DIR="${PROC_DIR}/ZIP"
export INPUT_DIR="${PROC_DIR}/DIM_INPUT" # Imported DIMAP raw data
export ML_SPK_DIR="${PROC_DIR}/ML_SPK"
export SPK_DIV_DIR="${PROC_DIR}/SPK_DIV"
export TEXTURE_DIR="${PROC_DIR}/TEXTURE"
export POLSAR_DIR="${PROC_DIR}/POLSAR"
export FINAL_DIR="${PROC_DIR}/FINAL"

#	0.3 Create Workspace
mkdir -p ${ZIP_DIR}
mkdir -p ${TMP_DIR}
mkdir -p ${INPUT_DIR}
mkdir -p ${ML_SPK_DIR}
mkdir -p ${SPK_DIV_DIR}
mkdir -p ${TEXTURE_DIR}
mkdir -p ${POLSAR_DIR}
mkdir -p ${FINAL_DIR}

#	0.4 DEM File for Geocoding
DEM_FILE='/home/avollrath/test/final_dem_filled.tif'

#----------------------------------------------------------------------
# 	1 Import Raw data to DIMAP format compatible with S1TBX
#----------------------------------------------------------------------

# 	move data 
#mv ${PROC_DIR}/*zip ${ZIP_DIR}

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

	# extract Date and Footprint
	YEAR=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 2-5`
	DATE=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 2-9`
	UL_LAT=`cat workreport | grep Brs_ImageSceneLeftTopLatitude | awk -F "=" $'{print $2}' | sed 's/\"//g'`
#	UL_LAT=`cat workreport | grep Brs_ImageSceneLeftTopLatitude | awk -F "=" $'{print $2}' | sed 's/\"//g'`
	
	FRAME=`echo ${SCENE_ID}	| cut -c 12-15`	

	# !!!!!needs change for final version!!!!!	
	#SAT_PATH=`curl http://api.daac.asf.alaska.edu/services/search/param?keyword=value\&granule_list=${SCENE_ID}\&output=csv | tail -n 1 | awk -F "," $'{print $7}' | sed 's/\"//g'`
	
	#echo "$FRAME $PATH $YEAR $UL_LAT"

#----------------------------------------------------------------------
# 	1 Import Raw data to DIMAP format compatible with S1TBX
#----------------------------------------------------------------------

	# define input/output
	INPUT_RAW=${TMP_DIR}/${SCENE_ID}/${VOLUME_FILE}	
	OUTPUT_DIMAP=${INPUT_DIR}/${SCENE_ID}.dim

	# Write new xml graph and substitute input and output files
	cp ${NEST_GRAPHS}/ALOS_L1.1_NEST_import.xml ${TMP_DIR}/Import_DIMAP.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|<file>INPUT_RAW</file>|<file>${INPUT_RAW}</file>|g" ${TMP_DIR}/Import_DIMAP.xml
	# insert Input file path into processing chain xml
	sed -i "s|<file>OUTPUT_DIMAP</file>|<file>${OUTPUT_DIMAP}</file>|g" ${TMP_DIR}/Import_DIMAP.xml

	echo "Importing CEOS files to BEAM_DIMAP file format for ${SCENE_ID}"
	sh ${NEST_EXE} ${TMP_DIR}/Import_DIMAP.xml

#----------------------------------------------------------------------
# 	2 Create multilooked, Lee speckle-filtered intensities
#----------------------------------------------------------------------	

	# define output
	OUTPUT_ML_SPK=${ML_SPK_DIR}/${SCENE_ID}"_ML_SPK.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_DSK_ML_SPK.xml ${TMP_DIR}/ML_SPK.xml

	# insert Input file path into processing chain xml
	sed -i "s|<file>INPUT_DIMAP</file>|<file>${OUTPUT_DIMAP}</file>|g" ${TMP_DIR}/ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|<file>OUTPUT_ML_SPK</file>|<file>${OUTPUT_ML_SPK}</file>|g" ${TMP_DIR}/ML_SPK.xml

	echo "Apply Multi-look & Speckle Filter to ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/ML_SPK.xml

			
#----------------------------------------------------------------------
# 	3 Create Speckle Divergence files
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_SPK_DIV=${SPK_DIV_DIR}/${SCENE_ID}"_SPK_DIV.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_DSK_SPK-DIV_ML.xml ${TMP_DIR}/SPK_DIV.xml

	# insert Input file path into processing chain xml
	sed -i "s|<file>INPUT_DIMAP</file>|<file>${OUTPUT_DIMAP}</file>|g" ${TMP_DIR}/SPK_DIV.xml
	# insert Input file path into processing chain xml
	sed -i "s|<file>OUTPUT_SPK_DIV</file>|<file>${OUTPUT_SPK_DIV}</file>|g" ${TMP_DIR}/SPK_DIV.xml

	echo "Calculate Speckle Divergence and apply Multi-looking for ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/SPK_DIV.xml

	
#----------------------------------------------------------------------
# 	4 Create Polarimetric Products
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_POLSAR=${POLSAR_DIR}/${SCENE_ID}"_H_alpha.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_H_alpha.xml ${TMP_DIR}/POLSAR.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|<file>INPUT_DIMAP</file>|<file>${OUTPUT_DIMAP}</file>|g" ${TMP_DIR}/POLSAR.xml
	# insert Input file path into processing chain xml
	sed -i "s|<file>OUTPUT_POLSAR</file>|<file>${OUTPUT_POLSAR}</file>|g" ${TMP_DIR}/POLSAR.xml

	echo "Calculate H-alpha dual pol decomposition for ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/POLSAR.xml


#----------------------------------------------------------------------
# 	5 Geocode Products
#----------------------------------------------------------------------	


	# 5a	Geocode Multi-looked, speckle-filtered imagery

	OUTPUT_ML_SPK_TR=${FINAL_DIR}/${SCENE_ID}'_ML_SPK_TR.tif'
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_radiometric.xml ${TMP_DIR}/TR_ML_SPK.xml

	# insert Input file path into processing chain xml
	sed -i "s|<file>INPUT_TR</file>|<file>${OUTPUT_SPK_DIV}</file>|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert Input file path into processing chain xml
	sed -i "s|<file>OUTPUT_TR</file>|<file>${OUTPUT_SPK_DIV_TR}</file>|g" ${TMP_DIR}/TR_ML_SPK.xml
	# insert DEM path
	sed -i "s|<externalDEMFile>DEM_FILE</externalDEMFile>|<externalDEMFile>${DEM_FILE}</externalDEMFile>|g" ${TMP_DIR}/TR_ML_SPK.xml

	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Multi-looked, speckle-filtered scene: ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml
	


	# 5b	Geocode Speckle-Divergence

	# define output file name
	OUTPUT_SPK_DIV_TR=${FINAL_DIR}/${SCENE_ID}'_SPK_DIV_TR.tif'
	# copy template xml graph into tmp folder 
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_SPK_DIV.xml ${TMP_DIR}/TR_SPK_DIV.xml

	# insert Input file path into processing chain xml
	sed -i "s|<file>INPUT_TR</file>|<file>${OUTPUT_SPK_DIV}</file>|g" ${TMP_DIR}/TR_SPK_DIV.xml
	# insert Input file path into processing chain xml
	sed -i "s|<file>OUTPUT_TR</file>|<file>${OUTPUT_SPK_DIV_TR}</file>|g" ${TMP_DIR}/TR_SPK_DIV.xml
	# insert external DEM path
	sed -i "s|<externalDEMFile>DEM_FILE</externalDEMFile>|<externalDEMFile>${DEM_FILE}</externalDEMFile>|g" ${TMP_DIR}/TR_SPK_DIV.xml

	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Speckle-Divergence from scene: ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/TR_SPK_DIV.xml
	

	# 5c	Multi-look & Geocode Polsar H-alpha dual pol data (multilook included, since it does not work for the preproc chain)

	# define output file name
	OUTPUT_POLSAR_TR=${FINAL_DIR}/${SCENE_ID}'_H_ALPHA_TR.tif'
	# copy template xml graph into tmp folder
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_ML_H_alpha.xml ${TMP_DIR}/TR_H_alpha.xml

	# insert Input file path into processing chain xml
	sed -i "s|<file>INPUT_TR</file>|<file>${OUTPUT_POLSAR}</file>|g" ${TMP_DIR}/TR_H_alpha.xml
	# insert Input file path into processing chain xml
	sed -i "s|<file>OUTPUT_TR</file>|<file>${OUTPUT_POLSAR_TR}</file>|g" ${TMP_DIR}/TR_H_alpha.xml
	# insert external DEM path
	sed -i "s|<externalDEMFile>DEM_FILE</externalDEMFile>|<externalDEMFile>${DEM_FILE}</externalDEMFile>|g" ${TMP_DIR}/TR_H_alpha.xml

	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Speckle-Divergence from scene: ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/TR_H_alpha.xml

#----------------------------------------------------------------------
# 	5 Remove tmp files
#----------------------------------------------------------------------	

	rm -rf ${TMP_DIR}/*
done
