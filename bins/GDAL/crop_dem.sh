#! /bin/bash

# crop DEM for scene size

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------

# 	0.1 Check for right usage
if [ "$#" != "3" ]; then
  echo -e "Usage: osk_bulk_ALOS_L1_1_preprocess </path/to/unpacked/scene> </path/to/dem> </path/to/cropped/dem>"
  echo -e "The path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Processing folder: ${PROC_DIR}"
fi



cd ${PROC_DIR}
LT_LAT=`cat workreport | grep Brs_ImageSceneLeftTopLatitude | awk -F"=" $'{print $2}' | sed 's|"||g'`
LT_LON=`cat workreport | grep Brs_ImageSceneLeftTopLongitude | awk -F"=" $'{print $2}' | sed 's|"||g'`
RB_LAT=`cat workreport | grep Brs_ImageSceneRightBottomLatitude | awk -F"=" $'{print $2}' | sed 's|"||g'`
RB_LON=`cat workreport | grep Brs_ImageSceneRightBottomLongitude | awk -F"=" $'{print $2}' | sed 's|"||g'`

RT_LAT=`cat workreport | grep Brs_ImageSceneRightTopLatitude | awk -F"=" $'{print $2}' | sed 's|"||g'`
RT_LON=`cat workreport | grep Brs_ImageSceneRightTopLongitude | awk -F"=" $'{print $2}' | sed 's|"||g'`
LB_LAT=`cat workreport | grep Brs_ImageSceneLeftBottomLatitude | awk -F"=" $'{print $2}' | sed 's|"||g'`
LB_LON=`cat workreport | grep Brs_ImageSceneLeftBottomLongitude | awk -F"=" $'{print $2}' | sed 's|"||g'`

LT_LAT_BUF=`echo "${LT_LAT} + 0.175" | bc`
LT_LON_BUF=`echo "${LT_LON} - 0.175" | bc`
RB_LAT_BUF=`echo "${RB_LAT} - 0.175" | bc`
RB_LON_BUF=`echo "${RB_LON} + 0.175" | bc`


gdal_translate -of GTiff -a_nodata -0 -projwin ${LT_LON_BUF} ${LT_LAT_BUF} ${RB_LON_BUF} ${RB_LAT_BUF} $2 $3 #tmp_dem.tif
#gdal_calc.py -A tmp_dem.tif --outfile=$3 --overwrite --calc="0*(A==-32768)" --NoDataValue=0
rm tmp_dem.tif
