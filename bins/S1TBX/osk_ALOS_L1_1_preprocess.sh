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
	# define input/output
	export INPUT_RAW=${TMP_DIR}/${SCENE_ID}/${VOLUME_FILE}	
	export OUTPUT_DIMAP=${INPUT_DIR}/${SCENE_ID}.dim

	# Write new xml graph and substitute input and output files
	
	while read LINE; do
		
		INPUT_TEST=`echo ${LINE} | grep "INPUT_RAW"`
		OUTPUT_TEST=`echo ${LINE} | grep "OUTPUT_DIMAP"`
	
		# check if it is the input file line 
		if [[ "$INPUT_TEST" != "" ]] ;then 
			

			# write path of input file into graph.xml
			INPUT_LINE=`echo ${LINE} | sed "s|INPUT_RAW|${INPUT_RAW}|g"`
			echo ${INPUT_LINE} >> ${TMP_DIR}/Import_DIMAP.xml
		
		# check if it is the output file line
		elif [[ "$OUTPUT_TEST" != "" ]] ;then 
			
			# write path of output file into graph.xml
			OUTPUT_LINE=`echo ${LINE} | sed "s|OUTPUT_DIMAP|${OUTPUT_DIMAP}|g"`
			echo ${OUTPUT_LINE} >> ${TMP_DIR}/Import_DIMAP.xml
			
		
		# write line from template elsewise
		else
	
			echo ${LINE} >> ${TMP_DIR}/Import_DIMAP.xml

		fi

	done < ${NEST_GRAPHS}/ALOS_L1.1_NEST_import.xml
	
	# Execute the import
	echo "Importing CEOS files to BEAM_DIMAP file format for ${SCENE_ID}"
	sh ${NEST_EXE} ${TMP_DIR}/Import_DIMAP.xml

#----------------------------------------------------------------------
# 	2 Create multilooked, Lee speckle-filtered intensities
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_ML_SPK=${ML_SPK_DIR}/${SCENE_ID}"_ML_SPK.dim"

	while read LINE; do

	INPUT_TEST=`echo ${LINE} | grep "INPUT_DIMAP"`
	OUTPUT_TEST=`echo ${LINE} | grep "OUTPUT_ML_SPK"`
	
#		# check if it is the input file line 
		if [[ "$INPUT_TEST" != "" ]] ;then 
			
			# write path of input file into graph.xml
			INPUT_LINE=`echo ${LINE} | sed "s|INPUT_DIMAP|${OUTPUT_DIMAP}|g"`
			echo ${INPUT_LINE} >> ${TMP_DIR}/ML_SPK.xml
		
		# check if it is the output file line
		elif [[ "$OUTPUT_TEST" != "" ]] ;then 
			
			# write path of output file into graph.xml
			OUTPUT_LINE=`echo ${LINE} | sed "s|OUTPUT_ML_SPK|${OUTPUT_ML_SPK}|g"`
			echo ${OUTPUT_LINE} >> ${TMP_DIR}/ML_SPK.xml
				
		# write line from template elsewise
		else

			echo ${LINE} >> ${TMP_DIR}/ML_SPK.xml

		fi

	done < ${S1TBX_GRAPHS}/ALOS_FBD_1_1_DSK_ML_SPK.xml

	echo "Apply Multi-look & Speckle Filter to ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/ML_SPK.xml

			
#----------------------------------------------------------------------
# 	3 Create Speckle Divergence files
#----------------------------------------------------------------------	

	# define path/name of output
	OUTPUT_SPK_DIV=${SPK_DIV_DIR}/${SCENE_ID}"_SPK_DIV.dim"

	while read LINE; do

	INPUT_TEST=`echo ${LINE} | grep "INPUT_DIMAP"`
	OUTPUT_TEST=`echo ${LINE} | grep "OUTPUT_SPK_DIV"`
	
		# check if it is the input file line 
		if [[ "$INPUT_TEST" != "" ]] ;then 
			
			# write path of input file into graph.xml
			INPUT_LINE=`echo ${LINE} | sed "s|INPUT_DIMAP|${OUTPUT_DIMAP}|g"`
			echo ${INPUT_LINE} >> ${TMP_DIR}/SPK_DIV.xml
		
		# check if it is the output file line
		elif [[ "$OUTPUT_TEST" != "" ]] ;then 
			
			# write path of output file into graph.xml
			OUTPUT_LINE=`echo ${LINE} | sed "s|OUTPUT_SPK_DIV|${OUTPUT_SPK_DIV}|g"`
			echo ${OUTPUT_LINE} >> ${TMP_DIR}/SPK_DIV.xml
				
		# write line from template elsewise
		else

			echo ${LINE} >> ${TMP_DIR}/SPK_DIV.xml

		fi

	done < ${S1TBX_GRAPHS}/ALOS_FBD_1_1_DSK_SPK-DIV_ML.xml

	echo "Calculate Speckle Divergence and apply Multi-looking for ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/SPK_DIV.xml

	


#----------------------------------------------------------------------
# 	4 Create Polarimetric Products
#----------------------------------------------------------------------	

	# define path/name of output
#	OUTPUT_POLSAR=${POLSAR_DIR}/${SCENE_ID}"_H_alpha.dim"

#	while read LINE; do

#	INPUT_TEST=`echo ${LINE} | grep "INPUT_DIMAP"`
#	OUTPUT_TEST=`echo ${LINE} | grep "OUTPUT_SPK_DIV"`
	
		# check if it is the input file line 
#		if [[ "$INPUT_TEST" != "" ]] ;then 
			
			# write path of input file into graph.xml
#			INPUT_LINE=`echo ${LINE} | sed "s|INPUT_DIMAP|${OUTPUT_DIMAP}|g"`
#			echo ${INPUT_LINE} >> ${TMP_DIR}/POLSAR.xml
		
		# check if it is the output file line
#		elif [[ "$OUTPUT_TEST" != "" ]] ;then 
			
			# write path of output file into graph.xml
#			OUTPUT_LINE=`echo ${LINE} | sed "s|OUTPUT_POLSAR|${OUTPUT_POLSAR}|g"`
#			echo ${OUTPUT_LINE} >> ${TMP_DIR}/POLSAR.xml
				
		# write line from template elsewise
#		else

#			echo ${LINE} >> ${TMP_DIR}/POLSAR.xml

#		fi

#	done < ${S1TBX_GRAPHS}/ALOS_FBD_1_1_H_alpha_ML.xml

#	echo "Calculate H-alpha dual pol decomposition for ${SCENE_ID}"
#	sh ${S1TBX_EXE} ${TMP_DIR}/POLSAR.xml

#----------------------------------------------------------------------
# 	5 Geocode Products
#----------------------------------------------------------------------	

DEM_FILE='/home/avollrath/test/final_dem_filled.tif'
OUTPUT_ML_SPK_TR=${FINAL_DIR}/${SCENE_ID}'_ML_SPK_TR.tif'

OUTPUT_POLSAR_TR=${FINAL_DIR}/${SCENE_ID}'_POLSAR_TR.tif'


	# 5a	Geocode Multi-looked, speckle-filtered imagery


	while read LINE; do

	INPUT_TEST=`echo ${LINE} | grep "INPUT_TR"`
	OUTPUT_TEST=`echo ${LINE} | grep "OUTPUT_TR"`
	
		# check if it is the input file line 
		if [[ "$INPUT_TEST" != "" ]] ;then 
			
			# write path of input file into graph.xml
			INPUT_LINE=`echo ${LINE} | sed "s|INPUT_TR|${OUTPUT_ML_SPK}|g"`
			echo ${INPUT_LINE} >> ${TMP_DIR}/TR_ML_SPK.xml
		
		# check if it is the output file line
		elif [[ "$OUTPUT_TEST" != "" ]] ;then 
			
			# write path of output file into graph.xml
			OUTPUT_LINE=`echo ${LINE} | sed "s|OUTPUT_TR|${OUTPUT_ML_SPK_TR}|g"`
			echo ${OUTPUT_LINE} >> ${TMP_DIR}/TR_ML_SPK.xml
				
		# write line from template elsewise
		else

			echo ${LINE} >> ${TMP_DIR}/TR_ML_SPK.xml

		fi

	done < ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_radiometric.xml

	# insert DEM path
	sed -i "s|<externalDEMFile>DEM_FILE</externalDEMFile>|<externalDEMFile>${DEM_FILE}</externalDEMFile>|g" ${TMP_DIR}/TR_ML_SPK.xml

	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Multi-looked, speckle-filtered scene: ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml
	


	# 5b	Geocode Speckle-Divergence


	OUTPUT_SPK_DIV_TR=${FINAL_DIR}/${SCENE_ID}'_SPK_DIV_TR.tif'
	
	while read LINE; do

	INPUT_TEST=`echo ${LINE} | grep "INPUT_TR"`
	OUTPUT_TEST=`echo ${LINE} | grep "OUTPUT_TR"`
	
		# check if it is the input file line 
		if [[ "$INPUT_TEST" != "" ]] ;then 
			
			# write path of input file into graph.xml
			INPUT_LINE=`echo ${LINE} | sed "s|INPUT_TR|${OUTPUT_SPK_DIV}|g"`
			echo ${INPUT_LINE} >> ${TMP_DIR}/TR_SPK_DIV.xml
		
		# check if it is the output file line
		elif [[ "$OUTPUT_TEST" != "" ]] ;then 
			
			# write path of output file into graph.xml
			OUTPUT_LINE=`echo ${LINE} | sed "s|OUTPUT_TR|${OUTPUT_SPK_DIV_TR}|g"`
			echo ${OUTPUT_LINE} >> ${TMP_DIR}/TR_SPK_DIV.xml
				
		# write line from template elsewise
		else

			echo ${LINE} >> ${TMP_DIR}/TR_SPK_DIV.xml

		fi

	done < ${S1TBX_GRAPHS}/ALOS_FBD_1_1_TR_SPK_DIV.xml

	# insert external DEM path
	sed -i "s|<externalDEMFile>DEM_FILE</externalDEMFile>|<externalDEMFile>${DEM_FILE}</externalDEMFile>|g" ${TMP_DIR}/TR_SPK_DIV.xml

	
	# Radiometrically terrain correcting Multi-looked, speckle-filtered files
	echo "Geocode Speckle-Divergence from scene: ${SCENE_ID}"
	sh ${S1TBX_EXE} ${TMP_DIR}/TR_SPK_DIV.xml
	

#----------------------------------------------------------------------
# 	5 Remove tmp files
#----------------------------------------------------------------------	

	rm -rf ${TMP_DIR}/*
done
