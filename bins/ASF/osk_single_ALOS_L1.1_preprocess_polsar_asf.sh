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
  echo -e "Usage: osk_ALOS_L1_1_preprocess /path/to/zip /path/to/dem"
  echo -e "The path will be your Project folder!"
  exit 1
else
  echo "Welcome to OpenSARKit!"
# set up input data
  FILE=`readlink -f $1`
  PROC_DIR=`dirname ${FILE}`
  TMP_DIR=${PROC_DIR}/TMP
  mkdir -p ${TMP_DIR}
  DEM_FILE=$2
  echo "Processing folder: ${PROC_DIR}"
fi

# Parameters maybe to be included later
LOOKS_AZI=4
LOOKS_RANGE=1
MEMORY=4000


echo "Extracting ${FILE}"
unzip -o -q ${FILE} -d ${TMP_DIR}

# extract filenames
SCENE_ID=`ls ${TMP_DIR}`

cd ${TMP_DIR}/${SCENE_ID}

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
SAT_PATH=`curl -s https://api.daac.asf.alaska.edu/services/search/param?keyword=value\&granule_list=${SCENE_ID:0:15}\&output=csv | tail -n 1 | awk -F "," $'{print $7}' | sed 's/\"//g'`
	
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

#------------------------------------------------------
#	1) PolSARPro Import & MultiLooking 
#------------------------------------------------------

#---------------------------------------
# Get Original Image Files
VOLUME_FILE=`ls VOL*`
LEADER_FILE=`ls LED*`
IMAGE_FILE=`ls IMG-HH*`
IMAGE_HV=`ls IMG-HV*`
TRAILER_FILE=`ls TRL*`
#---------------------------------------

#---------------------------------------
# Import Scene
echo "Importing Scene ${Scene_ID:0:15} to PolSARPro"
alos_header.exe -od "${TMP_DIR}" -ilf "${LEADER_FILE}" -iif "${IMAGE_FILE}" -itf "${TRAILER_FILE}" -ocf "${TMP_DIR}/tmp_config"
#---------------------------------------

#---------------------------------------
# create C2 Folder
C2=${TMP_DIR}/C2
mkdir -p ${C2}
#---------------------------------------

#---------------------------------------
# get nr. of rows & columns for raw image
ROWS_RAW=`awk 'NR==2' ${TMP_DIR}/tmp_config`
COLS_RAW=`awk 'NR==5' ${TMP_DIR}/tmp_config`
#---------------------------------------

#---------------------------------------
# Transform to C2 Matrix and multilook
echo "Computing the Dual Polarized Covariance Matrix"
alos_convert_11_dual.exe -if1 "${IMAGE_FILE}" -if2 "${IMAGE_HV}" -od ${C2} -odf SPPC2 -nr ${ROWS_RAW} -nc ${COLS_RAW} -ofr 0 -ofc 0 -fnr ${ROWS_RAW} -fnc ${COLS_RAW} -cf "${TMP_DIR}/tmp_config"  -pp pp1 -nlr ${LOOKS_AZI} -nlc ${LOOKS_RANGE}  -ssr 1 -ssc 1 -mem ${MEMORY} -errf "${TMP_DIR}/MemoryAllocError.txt"
#-------------------------------------------

#---------------------------------------
# get nr. of rows & col for ML image
ROWS_ML=`awk 'NR==2' ${C2}/config.txt`
COLS_ML=`awk 'NR==5' ${C2}/config.txt`
echo ${ROWS_ML}
echo ${COLS_ML}
#---------------------------------------

#---------------------------------------
# Create ENVI hdr file
cp ${POLSAR_CONF}/generic.hdr ${C2}/C11.bin.hdr
sed -i "s|samples =|samples = ${COLS_ML} |g" ${C2}/C11.bin.hdr
sed -i "s|lines   =|lines   = ${ROWS_ML} |g" ${C2}/C11.bin.hdr
sed -i "s|BAND|C11.bin}|g" ${C2}/C11.bin.hdr

cp ${C2}/C11.bin.hdr ${C2}/C12_real.bin.hdr
cp ${C2}/C11.bin.hdr ${C2}/C12_imag.bin.hdr
cp ${C2}/C11.bin.hdr ${C2}/C22.bin.hdr
cp ${C2}/C11.bin.hdr ${C2}/mask_valid_pixels.bin.hdr

sed -i "s|band names = {C11.bin}|band names  = {C12_real.bin}|g" ${C2}/C12_real.bin.hdr
sed -i "s|band names = {C11.bin}|band names  = {C12_imag.bin}|g" ${C2}/C12_imag.bin.hdr
sed -i "s|band names = {C11.bin}|band names  = {C22.bin}|g" ${C2}/C22.bin.hdr
sed -i "s|band names = {C11.bin}|band names  = {mask_valid_pixels.bin}|g" ${C2}/mask_valid_pixels.bin.hdr
#--------------------------------------------------------

#---------------------------------------
# Masking for valid values
echo "Create a mask for valid pixels"
create_mask_valid_pixels.exe -id ${C2} -od ${C2} -idf C2 -ofr 0 -ofc 0 -fnr ${ROWS_ML} -fnc ${COLS_ML}

echo "Apply the mask for all channels"
#apply_mask_valid_pixels.exe -bf "${C2}/mask_valid_pixels.bin" -od "${C2}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}
apply_mask_valid_pixels.exe -bf "${C2}/C11.bin" -od "${C2}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}
apply_mask_valid_pixels.exe -bf "${C2}/C12_imag.bin" -od "${C2}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}
apply_mask_valid_pixels.exe -bf "${C2}/C12_real.bin" -od "${C2}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}
apply_mask_valid_pixels.exe -bf "${C2}/C22.bin" -od "${C2}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}

#---------------------------------------
# Create RGB Composite for ML image
create_rgb_file_SPPIPPC2.exe -id "${C2}" -of "${C2}/PauliRGB.bmp" -iodf C2 -ofr 0 -ofc 0 -fnr ${ROWS_ML} -fnc ${COLS_ML} -mem ${MEMORY} -errf "${TMP_DIR}/MemoryAllocError.txt" -rgbf RGB1 -mask "${C2}/mask_valid_pixels.bin" -auto 1
#--------------------------------------

#------------------------------------------------------
#	2) PolSARPro Speckle filtering
#------------------------------------------------------

C2_SPK_REF=${TMP_DIR}/C2_SPK_REF
mkdir -p ${C2_SPK_REF}
cp ${C2}/config.txt ${C2_SPK_REF}/config.txt 
cp ${C2}/*hdr ${C2_SPK_REF}/

#---------------------------------------
# Run Speckle filter
echo "Apply Lee Refined Filter (5x5 window size, 1 nr. of look)"
lee_refined_filter.exe -id ${C2} -od ${C2_SPK_REF} -iodf C2 -ofr 0 -ofc 0 -fnr ${ROWS_ML} -fnc ${COLS_ML} -nlk 1 -nw 7 -mem ${MEMORY} -errf "${TMP_DIR}/MemoryAllocError.txt" -mask "${C2}/mask_valid_pixels.bin"

#---------------------------------------
# Masking for valid values
echo "Create a mask for valid pixels"
create_mask_valid_pixels.exe -id ${C2_SPK_REF} -od ${C2_SPK_REF} -idf C2 -ofr 0 -ofc 0 -fnr ${ROWS_ML} -fnc ${COLS_ML}

echo "Apply the mask for all channels"
#apply_mask_valid_pixels.exe -bf "${C2_SPK_REF}/mask_valid_pixels.bin" -od "${C2_SPK_REF}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML} # PolSAR makes this, but seems to be useless
apply_mask_valid_pixels.exe -bf "${C2_SPK_REF}/C11.bin" -od "${C2_SPK_REF}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML} # PolSAR bug -od is wrong, should be -mf
apply_mask_valid_pixels.exe -bf "${C2_SPK_REF}/C12_imag.bin" -od "${C2_SPK_REF}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}
apply_mask_valid_pixels.exe -bf "${C2_SPK_REF}/C12_real.bin" -od "${C2_SPK_REF}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}
apply_mask_valid_pixels.exe -bf "${C2_SPK_REF}/C22.bin" -od "${C2_SPK_REF}/mask_valid_pixels.bin" -iodf 4 -fnr ${ROWS_ML} -fnc ${COLS_ML}

create_rgb_file_SPPIPPC2.exe -id "${C2_SPK_REF}" -of "${C2_SPK_REF}/PauliRGB.bmp" -iodf C2 -ofr 0 -ofc 0 -fnr ${ROWS_ML} -fnc ${COLS_ML} -mem ${MEMORY} -errf "${TMP_DIR}/MemoryAllocError.txt" -rgbf RGB1 -mask "${C2_SPK_REF}/mask_valid_pixels.bin" -auto 1
#------------------------------------------------------

#------------------------------------------------------
#	3) Geocoding
#------------------------------------------------------

# define output folder

OUTPUT_GEO=${TMP_DIR}/C2_GEO
mkdir -p ${OUTPUT_GEO}

echo "create DEM crop"
CROP_DEM=${TMP_DIR}/tmp_crop_dem
bash ${GDAL_BIN}/crop_dem.sh ${TMP_DIR}/${SCENE_ID} ${DEM_FILE} ${CROP_DEM}
cd ${TMP_DIR}/${SCENE_ID}

#gdalwarp -s_srs EPSG:4326 -t_srs EPSG:32644 -tr 30 30 -srcnodata 0 -dstnodata 0 ${CROP_DEM}-2 ${CROP_DEM}

#cp ${ASF_CONF}/geocoding_alos_fbd.cfg ${TMP_DIR}/geocoding_alos_fbd.cfg
#sed -i "s|input file =|input file = ${C2_SPK_REF}|g" ${TMP_DIR}/geocoding_alos_fbd.cfg
#sed -i "s|output file =|output file = ${C2_SPK_REF}|g" ${TMP_DIR}/geocoding_alos_fbd.cfg
#sed -i "s|ancillary file =|ancillary file = ${LEADER_FILE}|g" ${TMP_DIR}/geocoding_alos_fbd.cfg
#sed -i "s|model = |model = ${CROP_DEM}|g" ${TMP_DIR}/geocoding_alos_fbd.cfg
#sed -i "s|tmp dir =|tmp dir = ${TMP_DIR}|g" ${TMP_DIR}/geocoding_alos_fbd.cfg
#sed -i "s|projection =|projection = ${ASF_CONF}/Proj.proj|g" ${TMP_DIR}/geocoding_alos_fbd.cfg

#---------------------------------------------
# ASF Fine Coregistration

#---------IMPORT---------#
# a) Import from Polsar to ASF
asf_import -format polsarpro -band AMP -ancillary-file ${LEADER_FILE} ${C2_SPK_REF}/C11.bin ${C2_SPK_REF}/asf_c11 # eventually band 2
# get polsarband
adjust_bands -band POLSARPRO ${C2_SPK_REF}/asf_c11.img ${C2_SPK_REF}/asf_c11_polsar.img

# b) Import DEM to ASF Format
asf_import -format 'geotiff' -image-data-type 'elevation' ${CROP_DEM} ${CROP_DEM}"_asf"
meta2envi ${CROP_DEM}"_asf.meta" ${CROP_DEM}"_asf.img.hdr"

#---------Rough TC---------#

# do rough terrain correction
asf_terrcorr -do-radiometric -use-nearest-neighbor -keep ${C2_SPK_REF}/asf_c11_polsar.img ${CROP_DEM}"_asf.img" ${C2_SPK_REF}/c11_tc_rough.img # we get the simulated SAR image in radar geometry
# do terrain correction for simultaed sar (we need the image 
#asf_terrcorr -use-nearest-neighbor -k ${C2_SPK_REF}/tmp_crop_dem_asf_sim_sar_trim.img ${CROP_DEM}"_asf.img" ${C2_SPK_REF}/sim_sar_tc.img

#---------Rough GC---------#
# geocode both files
#asf_geocode -p utm -datum WGS84 -pixel-size 15 ${C2_SPK_REF}/c11_tc_rough.img ${C2_SPK_REF}/c11_geo_rough.img
#asf_geocode -p utm -datum WGS84 -pixel-size 15 ${C2_SPK_REF}/sim_sar_tc.img ${C2_SPK_REF}/sim_sar_geo.img

#---------Offset Refinement---------#
#  get offset file
#diffimage -output diff.offs ${C2_SPK_REF}/c11_geo_rough.img ${C2_SPK_REF}/sim_sar_geo.img
# create warps
#fit_warp ${C2_SPK_REF}/c11_geo_rough.offsets.txt ${C2_SPK_REF}/c11_geo_rough.img ${C2_SPK_REF}/4warp_c11
# resample geo_rough to sim sar
#remap -warp ${C2_SPK_REF}/4warp_c11 -nearest ${C2_SPK_REF}/c11_geo_rough.img ${C2_SPK_REF}/c11_geo.img

# back-geocoding
#to_sr ${C2_SPK_REF}/c11_geo.img ${C2_SPK_REF}/c11_geo_slant.img

#flip 
#flip v ${C2_SPK_REF}/c11_geo_slant.img ${C2_SPK_REF}/c11_geo_slant_flip.img


# recalculate to slant range

# create hdr files
#meta2envi ${C2_SPK_REF}/asf_c11_polsar.meta ${C2_SPK_REF}/asf_c11_polsar.img.hdr # we create some headers
#meta2envi ${C2_SPK_REF}/c11_tc_rough.meta ${C2_SPK_REF}/c11_tc_rough.img.hdr
#meta2envi ${C2_SPK_REF}/c11_geo_rough.meta ${C2_SPK_REF}/c11_geo_rough.img.hdr
#meta2envi ${C2_SPK_REF}/tmp_crop_dem_asf_sim_sar_trim.meta ${C2_SPK_REF}/tmp_crop_dem_asf_sim_sar_trim.img.hdr
#meta2envi ${C2_SPK_REF}/sim_sar_geo.meta ${C2_SPK_REF}/sim_sar_geo.img.hdr
#meta2envi ${C2_SPK_REF}/c11_tc_rough.meta ${C2_SPK_REF}/c11_tc_rough.img.hdr
#meta2envi ${C2_SPK_REF}/c11_geo_slant_flip.meta ${C2_SPK_REF}/c11_geo_slant_flip.img.hdr


# we calculate the offset of 
#fftMatch -m ${C2_SPK_REF}/offsets.txt -c ${C2_SPK_REF}/corr.ext -log ${C2_SPK_REF}/log ${C2_SPK_REF}/tmp_crop_dem_asf_sim_sar_trim.img ${C2_SPK_REF}/asf_c11.img
#DX=`cat ${C2_SPK_REF}/offsets.txt | awk $'{print $1}' `
#DY=`cat ${C2_SPK_REF}/offsets.txt | awk $'{print $2}'`

#fit_poly ${C2_SPK_REF}/corr.ext.img 3 ${C2_SPK_REF}/poly
#fit_warp ${C2_SPK_REF}/asf_c11_u_slant.offsets.txt ${C2_SPK_REF}/asf_c11_u.img ${C2_SPK_REF}/4warp
#remap -warp ${C2_SPK_REF}/4warp ${C2_SPK_REF}/asf_c11_u.img ${C2_SPK_REF}/asf_c11_u_ref.img



# change to true ML factors (ASF asumes 1/4 for ALOS)
#sed -i 's|azimuth_look_count: 4|azimuth_look_count: 9|g' ${C2_SPK_REF}/asf_c11.meta
#sed -i 's|range_look_count: 1|range_look_count: 2|g' ${C2_SPK_REF}/asf_c11.meta

#DR=`echo "${DX} * 9.36851"| bc`
#DA=`echo "${DY} * 12.712090882"| bc` 

#DR=`echo "${DX} * 9.36851"| bc`
#DA=`echo "${DY} * 12.712090882"| bc` 

#asf_terrcorr -offsets ${DX} ${DY} -do-radiometric -u -keep ${C2_SPK_REF}/asf_c11.img ${CROP_DEM}"_asf.img" ${C2_SPK_REF}/asf_c11_tc.img # we apply the offset to the geocding
#asf_terrcorr -offsets ${DR} ${DA} -do-radiometric -u -keep ${C2_SPK_REF}/asf_c11.img ${CROP_DEM}"_asf.img" ${C2_SPK_REF}/asf_c11_tc.img # we apply the offset to the geocding
#asf_terrcorr -do-radiometric -u ${C2_SPK_REF}/tmp_crop_dem_asf_sim_sar_trim.img ${CROP_DEM}"_asf.img" ${C2_SPK_REF}/asf_c11_simtc.img # we apply the offset to the geocding
#meta2envi ${C2_SPK_REF}/asf_c11_tc.meta ${C2_SPK_REF}/asf_c11_tc.img.hdr

#asf_geocode -p utm -datum WGS84 -pixel-size 30 ${C2_SPK_REF}/asf_c11_tc.img ${C2_SPK_REF}/asf_c11_geo.img
#meta2envi ${C2_SPK_REF}/asf_c11_geo.meta ${C2_SPK_REF}/asf_c11_geo.img.hdr
#!# othewise maybe diffimage, but we have to get the band out

#!# or
#fit_warp ${C2_SPK_REF}/asf_c11_u_slant.offsets.txt ${C2_SPK_REF}/asf_c11_u.img ${C2_SPK_REF}/4warp
#remap -warp ${C2_SPK_REF}/4warp ${C2_SPK_REF}/asf_c11_u.img ${C2_SPK_REF}/asf_c11_u_ref.img




