#! /bin/bash

#----------------------------------------------------------------------
#	ALOS Download from Alaska Space Facility (ASF)
#
#	Dependencies:
#
#		- curl
#		- ogr2ogr
#		- aria2
#
#----------------------------------------------------------------------


#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------

# 	0.1 Check for right usage
if [ "$#" != "2" ]; then
  echo -e "Usage: osk_download_ALOS_ASF </path/to/output> </path/to/AOI.shp> " # <start-date> <end-date>"
  echo -e "The output path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Automatically Downloading ALOS SLC data from ASF"
  echo "Download folder: ${PROC_DIR}"
fi

#get the cookie
read -r -p "Please type your ASF DAAC Username:" UNAME
echo -n "Please type your ASF DAAC Password:"
read -s PW

wget --save-cookies cookies.txt --post-data='user_name='$UNAME'&user_password='${PW}'' --no-check-certificate https://ursa.asfdaac.alaska.edu/cgi-bin/login -o /dev/null -O /dev/null


# get the footprint from the shapefile 
ogr2ogr -f CSV tmp_AOI_WKT.csv $2 -lco GEOMETRY=AS_WKT
AOI=`grep POLYGON tmp_AOI_WKT.csv | sed 's|\"POLYGON ((||g' | awk -F "))" $'{print $1}' | sed 's/\ /,/g'`

PERIOD="start=2008-12-31T11:59:59UTC&end=2010-01-01T00:00:00UTC"
PLATFORM="platform=A3"
PROCESSING="processingLevel=L1.1"
OUTPUT_FORMAT="output=csv"
OUTPUT="$1/inventory"
REL_ORBIT="relativeOrbit=112"
# Download dual polarized data
BEAM="beamMode=FBD"
mkdir -p ${PROC_DIR}/FBD

# search part of the URL
# for period
ASK="\&polygon=${AOI}&${PLATFORM}&${BEAM}&${PERIOD}&${PROCESSING}&${REL_ORBIT}&${OUTPUT_FORMAT}"
#ASK="\&polygon=${AOI}&${PLATFORM}&${BEAM}&${PROCESSING}&${OUTPUT_FORMAT}"

echo "Getting the inventory data"
curl -s http://api.daac.asf.alaska.edu/services/search/param?keyword=value$ASK | tail -n +2 > $OUTPUT-FBD.csv
NR_OF_PRODUCTS=`wc -l $OUTPUT-FBD.csv`
echo "Found ${NR_OF_PRODUCTS} products"

while read line;do 
	
	ACQ_YEAR=`echo $line | awk -F "," $'{print $9}' | cut -c 2-5`
	SAT_TRACK=`echo $line | awk -F "," $'{print $7}' | sed "s|\"||g"`
	DOWNLOAD=`echo $line | awk -F "," $'{print $26}' | sed "s|\"||g"`
	GRANULE=`echo $line | awk -F "," $'{print $1}' | sed "s|\"||g"`

	mkdir -p ${PROC_DIR}/FBD/${ACQ_YEAR}
	mkdir -p ${PROC_DIR}/FBD/${ACQ_YEAR}/${SAT_TRACK}

	cd ${PROC_DIR}/FBD/${ACQ_YEAR}/${SAT_TRACK}
	echo "Downloading ALOS FBD scene: ${GRANULE}"
	echo "from: ${DOWNLOAD}"
	echo "into: ${PROC_DIR}/FBD/${ACQ_YEAR}/${SAT_TRACK}"
	aria2c --load-cookies="${PROC_DIR}/cookies.txt" ${DOWNLOAD}

done < inventory-FBD.csv 

rm -rf ${PROC_DIR}/cookies.txt ${PROC_DIR}/tmp*


