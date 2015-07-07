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

# 	0.1 Check for right usage
if [ "$#" != "2" ]; then
  echo -e "Usage: osk_ALOS_L1_1_preprocess /path/to/zipped/scene.zip /path/to/dem"
  echo -e "The path will be your Project folder!"
  exit 1
else
  #cd $1
  #export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Processing folder: ${PROC_DIR}"
fi

# set up input data
FILE=`readlink -f $1`
PROC_DIR=`dirname ${FILE}`
TMP_DIR=${PROC_DIR}/TMP
mkdir -p ${TMP_DIR}

DEM_FILE=$2


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
echo "Acquisiton Mode:		${MODE}"
echo "Acquisition Date (YYYYMMDD):	${DATE}"
echo "Relative Satellite Track: 	${SAT_PATH}"
echo "Image Frame: 			$FRAME"
echo "----------------------------------------------------------------"

# be in line with preliminary processed path data
mkdir -p ${PROC_DIR}/../${DATE}
FINAL_DIR=${PROC_DIR}/../${DATE}/${FRAME}
mkdir -p ${FINAL_DIR}

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
	OUTPUT_GAMMA_HH=${FINAL_DIR}/${SCENE_ID}'_Gamma0_HH.dim'
	OUTPUT_GAMMA_HV=${FINAL_DIR}/${SCENE_ID}'_Gamma0_HV.dim'
	OUTPUT_LAYOVER=${TMP_DIR}/${SCENE_ID}'_Layover_Shadow.dim'

	# S1TBX version
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_SIM_TR_radiometric.xml ${TMP_DIR}/TR_ML_SPK.xml

	# NEST version
#	cp ${NEST_GRAPHS}/ALOS_L1.1_SIMTR2.xml ${TMP_DIR}/TR_ML_SPK.xml

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
#	sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
	
	# S1TBX 
	sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 

	# in case it fails try a another time	
	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 2nd time, since coarse offset did not start (NEST bug)"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
	#	sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
		sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
	fi

	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 3rd time, since coarse offset did not start (NEST bug)"
		echo "This time we will take 4000 GCPs (probably too much water in the scene)"
		sed -i "s|<numGCPtoGenerate>500|<numGCPtoGenerate>4000|g" ${TMP_DIR}/TR_ML_SPK.xml
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
#		sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
		sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
	fi

	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 4th time, since coarse offset did not start (NEST bug)"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${TMP_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
#		sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
		sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 

	fi

	if grep -q Error ${TMP_DIR}/tmplog || grep -q "does not have enough" ${TMP_DIR}/tmplog ; then 
		echo "Let's do it a 5th time, since coarse offset did not start (NEST bug)"
		rm -rf ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.dim" ${TMP_DIR}/${SCENE_ID}"_ML_SPK_TR.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HH.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.dim" ${FINAL_DIR}/${SCENE_ID}"_Gamma0_HV.data"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_Layover_Shadow.dim" ${FINAL_DIR}/${SCENE_ID}"_Layover_Shadow.data"
		rm ${TMP_DIR}/tmplog
#		sh ${NEST_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 
		sh ${S1TBX_EXE} ${TMP_DIR}/TR_ML_SPK.xml 2>&1 | tee  ${TMP_DIR}/tmplog 

	fi
	
	# exclude low backscatter pixel to eliminate border effect
	gdal_calc.py --overwrite -A ${FINAL_DIR}/${SCENE_ID}'_Gamma0_HH.data/Gamma0_HH.img' --outfile=${TMP_DIR}/tmp_mask_border_hh.tif --calc="A*(A>=0.001)" --NoDataValue=0
	gdal_calc.py --overwrite -A ${FINAL_DIR}/${SCENE_ID}'_Gamma0_HV.data/Gamma0_HV.img' --outfile=${TMP_DIR}/tmp_mask_border_hv.tif --calc="A*(A>=0.001)" --NoDataValue=0

	# tansform to SAGA
	#gdalwarp -srcnodata 0 -dstnodata -99999 -of SAGA ${TMP_DIR}/tmp_mask_border_hh.tif ${TMP_DIR}/tmp_mask_border_hh_saga.sdat
	#gdalwarp -srcnodata 0 -dstnodata -99999 -of SAGA ${TMP_DIR}/tmp_mask_border_hv.tif ${TMP_DIR}/tmp_mask_border_hv_saga.sdat

	# fill holes from previously eliminated pixels inside the scene
	echo "fill holes"
	cd ${TMP_DIR}
	#saga_cmd -f=r grid_tools 25 -GRID:tmp_mask_border_hh_saga.sgrd -MAXGAPCELLS:500 -MAXPOINTS:1000 -LOCALPOINTS:25 -CLOSED:tmp_mask_border_hh_filled.sgrd
	#saga_cmd -f=r grid_tools 25 -GRID:tmp_mask_border_hv_saga.sgrd -MAXGAPCELLS:500 -MAXPOINTS:1000 -LOCALPOINTS:25 -CLOSED:tmp_mask_border_hv_filled.sgrd

	# Apply Layover/Shadow mask
	echo "Invert Layover/Shadow Mask"	
	gdal_calc.py -A ${TMP_DIR}/${SCENE_ID}'_Layover_Shadow.data/layover_shadow_mask.img' --outfile=${TMP_DIR}/mask.tif --calc="1*(A==0)" --NoDataValue=0

	echo "Multiply inverted Layover/Shadow mask wih image layers"
 	gdal_calc.py -A ${TMP_DIR}/mask.tif -B ${TMP_DIR}/tmp_mask_border_hh.tif --outfile=${TMP_DIR}/tmp_Gamma0_HH2.tif --calc="A*B" --NoDataValue=0
	gdal_calc.py -A ${TMP_DIR}/mask.tif -B ${TMP_DIR}/tmp_mask_border_hv.tif --outfile=${TMP_DIR}/tmp_Gamma0_HV2.tif --calc="A*B" --NoDataValue=0


	echo "fill holes "
	# transform to SAGA format
	gdalwarp -srcnodata 0 -dstnodata -99999 -of SAGA ${TMP_DIR}/tmp_Gamma0_HH2.tif ${TMP_DIR}/tmp_mask_hh_saga.sdat
	gdalwarp -srcnodata 0 -dstnodata -99999 -of SAGA ${TMP_DIR}/tmp_Gamma0_HV2.tif ${TMP_DIR}/tmp_mask_hv_saga.sdat

	saga_cmd -f=r grid_tools 25 -GRID:tmp_mask_hh_saga.sgrd -MAXGAPCELLS:250 -MAXPOINTS:500 -LOCALPOINTS:25 -CLOSED:tmp_mask_hh_filled.sgrd
	saga_cmd -f=r grid_tools 25 -GRID:tmp_mask_hv_saga.sgrd -MAXGAPCELLS:250 -MAXPOINTS:500 -LOCALPOINTS:25 -CLOSED:tmp_mask_hv_filled.sgrd

	gdalwarp -srcnodata -99999 -dstnodata 0 -of ENVI ${TMP_DIR}/tmp_mask_hh_filled.sdat ${TMP_DIR}/tmp_mask_hh_saga.img
	gdalwarp -srcnodata -99999 -dstnodata 0 -of ENVI ${TMP_DIR}/tmp_mask_hv_filled.sdat ${TMP_DIR}/tmp_mask_hv_saga.img
	
	echo "Byteswap the layers due to GDAL BIGENDIAN output of ENVI format"
	osk_byteswap32.py ${TMP_DIR}/tmp_mask_hh_saga.img ${FINAL_DIR}/${SCENE_ID}'_Gamma0_HH.data/Gamma0_HH.img'
	osk_byteswap32.py ${TMP_DIR}/tmp_mask_hv_saga.img ${FINAL_DIR}/${SCENE_ID}'_Gamma0_HV.data/Gamma0_HV.img'


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
# 	5 Create Speckle Divergence files
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
# 	6 Create Polarimetric Products
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
# 	5 Texture
#----------------------------------------------------------------------	

	# HH texture calculations

	# define path/name of output
	OUTPUT_TEXTURE_HH=${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HH.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_Texture_HH.xml ${TMP_DIR}/TEXTURE_HH.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_GAMMA_HH_DB}|g" ${TMP_DIR}/TEXTURE_HH.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_TEXTURE_HH}|g" ${TMP_DIR}/TEXTURE_HH.xml

	echo "Calculate GLCM Texture measurements for HH channel"
	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HH.dim" ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HH.data"
		sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml
	fi

	# HV texture calculations

	# define path/name of output
	OUTPUT_TEXTURE_HV=${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HV.dim"
	# Write new xml graph and substitute input and output files
	cp ${S1TBX_GRAPHS}/ALOS_FBD_1_1_Texture_HV.xml ${TMP_DIR}/TEXTURE_HV.xml
	
	# insert Input file path into processing chain xml
	sed -i "s|INPUT_TR|${OUTPUT_GAMMA_HV_DB}|g" ${TMP_DIR}/TEXTURE_HV.xml
	# insert Input file path into processing chain xml
	sed -i "s|OUTPUT_TR|${OUTPUT_TEXTURE_HV}|g" ${TMP_DIR}/TEXTURE_HV.xml

	echo "Calculate GLCM Texture measurements for HV channel"
	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HV.xml 2>&1 | tee  ${TMP_DIR}/tmplog

	# in case it fails try a second time	
	if grep -q Error ${TMP_DIR}/tmplog; then 	
		echo "2nd try"
		rm -rf ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HV.dim" ${FINAL_DIR}/${SCENE_ID}"_TEXTURE_HV.data"
		sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HV.xml
	fi

#----------------------------------------------------------------------
# 	6 Create Session files 
#----------------------------------------------------------------------	

	
	#touch ${PROC_DIR}/session_Gamma0_HH.s1tbx
	#echo "<product>" >> ${PROC_DIR}/session_Gamma0_HH.s1tbx
	#echo "<refNo>$i</refNo>" >> ${PROC_DIR}/session_Gamma0_HH.s1tbx
	#echo "<uri>${DATE}/${FRAME}/${SCENE_ID}'_Gamma0_HH.dim</uri>" >> ${PROC_DIR}/session_Gamma0_HH.s1tbx
	#echo "</product>"  >> ${PROC_DIR}/session_Gamma0_HH.s1tbx

	#i=`expr $i + 1` 
#----------------------------------------------------------------------
# 	6 Remove tmp files
#----------------------------------------------------------------------	

rm -rf ${TMP_DIR}/


