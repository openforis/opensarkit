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
  echo "Processing $1"
fi

#	0.2 Define Workspace
export PROC_DIR="$1"
export TMP_DIR="${PROC_DIR}/TMP"
export ZIP_DIR="${PROC_DIR}/ZIP"
export TMP_DIR="${PROC_DIR}/TMP"
export RAW_DIR="${PROC_DIR}/RAW"
export INPUT_DIR="${PROC_DIR}/DIM_INPUT" # Imported DIMAP raw data
export FINAL_DIR="${PROC_DIR}/FINAL"

#	0.3 Create Workspace
mkdir -p ${ZIP_DIR}
mkdir -p ${TMP_DIR}
mkdir -p ${RAW_DIR}
mkdir -p ${INPUT_DIR}

# 	0.4 Source graph templates
export NEST_GRAPHS="/media/avollrath/phd_data2/FAO/S1TBX/Graphs/NEST/"
export S1TBX_GRAPHS="/media/avollrath/phd_data2/FAO/S1TBX/Graphs/S1TBX/"

#	0.5 Source progam executables
export S1TBX_EXE="/usr/programs/S1TBX/gpt.sh"
export NEST_EXE="/usr/programs/NEST/gpt.sh"

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

	# extract Date and Footprint
	YEAR=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 2-5`
	DATE=`cat workreport | grep Img_SceneCenterDateTime | awk -F "=" $'{print $2}' | cut -c 2-9`
	UL_LAT=`cat workreport | grep Brs_ImageSceneLeftTopLatitude | awk -F "=" '${print $2}' | sed 's/\"//g'`
	UL_LAT=`cat workreport | grep Brs_ImageSceneLeftTopLatitude | awk -F "=" '${print $2}' | sed 's/\"//g'`
	
	FRAME=`echo ${SCENE_ID}	| cut -c 12-14`	

	# !!!!!needs change for final version!!!!!	
	PATH=`curl http://api.daac.asf.alaska.edu/services/search/param?keyword=value\&granule_list=${SCENE_ID}\&output=csv | tail -n 1 | awk -F "," $'{print $7}' | sed 's/\"//g'`

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

	done < ${NEST_GRAPHS}/Alos_L1.1_Nest_import.xml
	
	# Execute the import
	sh ${NEST_EXE} ${TMP_DIR}/Import_DIMAP.xml

	rm -rf ${TMP_DIR}/*
		
#----------------------------------------------------------------------
# 	2 Create radiometrically corrected, Lee speckle-filtered gamma-backscatter files
#----------------------------------------------------------------------	

#----------------------------------------------------------------------
# 	3 Create texture files
#----------------------------------------------------------------------	

#----------------------------------------------------------------------
# 	4 Create Polarimetric Products
#----------------------------------------------------------------------	
	
done
