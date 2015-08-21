#! /bin/bash


# download and prepare SRTM3
# dependencies:

# gdal_tools
# gsutil python (google)
# spatialite
# ogr-tools
# 

#-------------------------------------------------------------------------------------------	
# 	0.1 Check for right usage & set up basic Script Variables
if [ "$#" != "2" ]; then
  echo -e "Usage: osk_ALOS_L1_1_preprocess <path/to/output> <ISO3 country code>"
  echo -e "Check for ISO3 code at http://www.fao.org/countryprofiles/iso3list/en/"	
  echo -e "The path will be your Project folder!"
  exit 1
else
  echo "Welcome to OpenSARKit!"
# set up input data
  cd $1
  PROC_DIR=`pwd`
  TMP_DIR=${PROC_DIR}/TMP
  mkdir -p ${TMP_DIR}
  ISO3=$2
  echo "Processing folder: ${PROC_DIR}"
fi
#---------------------------------------------------------------------------------------------


mkdir -p ${PROC_DIR}/AOI
mkdir -p ${TMP_DIR}/SRTM
mkdir -p ${PROC_DIR}/DEM
mkdir -p ${PROC_DIR}/LSAT
mkdir -p ${PROC_DIR}/LSAT/Inventory
mkdir -p ${PROC_DIR}/ALOS

cd ${PROC_DIR}
echo "get srtm3 tile list"
echo "SELECT s.COL,s.ROW FROM srtm3_grid as s, global_info as c WHERE \"iso3\" = \"${ISO3}\" AND ST_INTERSECTS(s.GEOM,c.GEOMETRY);" | spatialite -separator ' ' ${DB_GLOBAL} | head -50 > ${TMP_DIR}/srtm_list

echo "get LSAT tile list"
echo "SELECT l.path,l.row FROM landsat_wrs2_grid as l, global_info as c WHERE \"iso3\" = \"${ISO3}\" AND \"mode\" = \"D\" AND ST_INTERSECTS(l.GEOM,c.GEOMETRY);" | spatialite -separator ' ' ${DB_GLOBAL} | head -50 > ${PROC_DIR}/LSAT/Inventory/lsat_path_row_list.txt

rm -f ${PROC_DIR}/LSAT/Inventory/*inv.txt

echo "getting LSAT inventory data"
while read LINE; do 


	LSAT_PATH=`echo ${LINE} | awk $'{print $1}'`
	LSAT_ROW=`echo ${LINE} | awk $'{print $2}'`


	if [ `echo $LSAT_PATH | wc -m` == 2 ];then LSAT_PATH=00$LSAT_PATH;fi
	if [ `echo $LSAT_ROW | wc -m` == 2 ];then LSAT_ROW=00$LSAT_ROW;fi

	if [ `echo $LSAT_PATH | wc -m` == 3 ];then LSAT_PATH=0$LSAT_PATH;fi
	if [ `echo $LSAT_ROW | wc -m` == 3 ];then LSAT_ROW=0$LSAT_ROW;fi

# Date to DOY
# date -d '2007-01-01' +%j

	gsutil ls gs://earthengine-public/landsat/L5/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/L5_inv.txt
	gsutil ls gs://earthengine-public/landsat/L7/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/L7_inv.txt
	gsutil ls gs://earthengine-public/landsat/L8/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/L8_inv.txt

#   gsutil ls gs://earthengine-public/landsat/LM1/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/LM1_inv.txt
#   gsutil ls gs://earthengine-public/landsat/LM2/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/LM2_inv.txt
#   gsutil ls gs://earthengine-public/landsat/LM3/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/LM3_inv.txt
#	gsutil ls gs://earthengine-public/landsat/LM4/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/LM4_inv.txt
#	gsutil ls gs://earthengine-public/landsat/LM5/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/LM5_inv.txt
#	gsutil ls gs://earthengine-public/landsat/LT4/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/LT4_inv.txt
#	gsutil ls gs://earthengine-public/landsat/PE1/${LSAT_PATH}/${LSAT_ROW} >> ${PROC_DIR}/LSAT/Inventory/PE1_inv.txt

done < ${PROC_DIR}/LSAT/Inventory/lsat_path_row_list.txt

echo "extract AOI"
ogr2ogr -f "Esri Shapefile" ${PROC_DIR}/AOI/AOI.shp ${DB_GLOBAL} -dsco SPATIALITE=yes -where "\"iso3\" = \"${ISO3}\"" -nln AOI global_info

echo "convex hull"
osk_convex_hull.py --input ${PROC_DIR}/AOI/AOI.shp --output ${PROC_DIR}/AOI/${ISO3}"_convex_hull.shp"

echo "get wkt"
ogr2ogr -f CSV ${TMP_DIR}/tmp_AOI_WKT.csv ${PROC_DIR}/AOI/${ISO3}"_convex_hull.shp" -lco GEOMETRY=AS_WKT
AOI=`grep POLYGON ${TMP_DIR}/tmp_AOI_WKT.csv | sed 's|\"POLYGON ((||g' | awk -F "))" $'{print $1}' | sed 's/\ /,/g'`
#echo $AOI

#for LINE in `cat ${TMP_DIR}/srtm_list`;do
while read LINE; do
	echo $LINE
	COL=`echo ${LINE} | awk $'{print $1}'`
	ROW=`echo ${LINE} | awk $'{print $2}'`


	if [ `echo $ROW | wc -m` == 2 ];then ROW=0$ROW;fi
	if [ `echo $COL | wc -m` == 2 ];then COL=0$COL;fi
	
	wget http://droppr.org/srtm/v4.1/6_5x5_TIFs/srtm_$COL"_"$ROW.zip
	unzip -o -q srtm_$COL"_"$ROW.zip -d ${TMP_DIR}/SRTM
	rm -f srtm_$COL"_"$ROW.zip

done < ${TMP_DIR}/srtm_list

# merge SRTM tiles
gdal_merge.py -o ${TMP_DIR}/tmp_dem.tif -n -32768 -a_nodata -32768 ${TMP_DIR}/SRTM/*.tif
# recalculate 0's to 1
gdal_calc.py -A ${TMP_DIR}/tmp_dem.tif --outfile=${TMP_DIR}/tmp_dem2.tif --calc="(A==0)*1 + (A!=0)*A " 
# change -32767 to 0's
gdal_calc.py -A ${TMP_DIR}/tmp_dem2.tif --outfile=${PROC_DIR}/DEM/${ISO3}"_DEM_SRTM3V4.1.tif" --calc="(A==-32767)*0 + (A!=-32767)*A" --overwrite --NoDataValue=0

#rm -rf ${TMP_DIR}
