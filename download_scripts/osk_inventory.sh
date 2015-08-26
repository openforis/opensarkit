#! /bin/bash


# download and prepare SRTM3

#-------------------------------------------------------------------------------------------	
# 	0.1 Check for right usage & set up basic Script Variables
if [ "$#" != "3" ]; then
  echo -e "Usage: osk_ALOS_L1_1_preprocess /path/to/zip /path/to/dem /output/folder"
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

  mkdir -p $3
  cd $3
  OUT_DIR=`pwd`
fi

echo "SELECT s.COL,s.ROW FROM srtm3_grid as s, global_info as c WHERE \"iso3\" = \"${ISO}\" AND ST_INTERSECTS(s.GEOM,c.GEOMETRY);" | spatialite -separator ' ' global_info.sqlite | head -50 > ${TMP_DIR}/srtm_list
echo "SELECT l.path,l.row FROM landsat_wrs2_grid as l, global_info as c WHERE \"iso3\" = \"${ISO}\" AND \"mode\" = \"D\" AND ST_INTERSECTS(l.GEOM,c.GEOMETRY);" | spatialite -separator ' ' global_info.sqlite | head -50
 > ${TMP_DIR}/lsat_list

ogr2ogr -f "Esri Shapefile" ${PROC_DIR}/AOI.shp global_info global_info.sqlite -dsco SPATIALITE=yes -where "\"iso3\" = \"LKA\"" -nln AOI global_info
