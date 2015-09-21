#! /bin/bash 

#----------------------------------------------------------------------
#	Sentinel-1 Download from Scihub (ESA)
#
#	Dependencies:
#
#		- curl
#		- ogr2ogr
#     - xml-twig-tools
#----------------------------------------------------------------------

#-------------------------------------------------------------------------------------------	
# 	0.1 Check for right usage & set up basic Script Variables
if [ "$#" != "5" ]; then

	echo -e "*** Prepare project script ***"
	echo -e "*** OpenSARKit, v.01  ***"
	echo -e ""
	echo -e "usage: osk_download_ALOS_ASF <output_folder> <Area_of_Interest> <start_date> <end_date> <Product_type> <Polarization_Mode>"
	echo -e ""
	echo -e "input parameters:"
	echo -e "output_folder		(output) folder where the downloaded data will be saved"
	echo -e "Area_of_Interest	(input) Shapefile of your Area of interest"
	echo -e ""
	echo -e "Note: Use the convex_hull_aoi.shp prepared by osk_prepare_project script." 
	echo -e "      Otherwise the URL will be too long and the download won't start."
	echo -e ""
	echo -e "start_date		Start date of search in format YYYY-MM-DD"
	echo -e "end_date		End date of search in format YYYY-MM-DD"
	echo -e "Product_type			Acquisition Mode of Sentinel-1 SAR instrument"
	echo -e "			Available choices"
	echo -e "			  RAW (Fine-Beam Single Polarization)"
	echo -e "			  SLC (Fine-Beam Double Polarization)"
	echo -e "			  GRD (Polarimetric Mode)"
	echo -e ""
	echo -e "Polarization_Mode"			
	echo -e "			Available choices"
	echo -e "			  VH (for IWS Mode VV/VH)"
	echo -e "			  VV (for IWS VV)"
	echo -e "			  HH (for IWS HH/HV)"
	echo -e ""
	echo -e "Software dependencies:"
	echo -e "	- aria2"
	exit 1
else
	echo -e "*** Prepare project script ***"
	echo -e "*** OpenSARKit, v.01  ***"
   cd $1
   PROC_DIR=`pwd`
   TMP_DIR=${PROC_DIR}/TMP
   mkdir -p ${TMP_DIR}
	START=$3
	END=$4
	MODE=$5
fi

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------

# 	0.1 Check for right usage
if [ "$#" != "2" ]; then
  echo -e "Usage: osk_download_S1 </path/to/output> </path/to/AOI.shp> <start-date> <end-date>"
  echo -e "The output path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Automatically Downloading Sentinel-1 data from ESA Scihub"
  echo "Download folder: ${PROC_DIR}"
fi
TMP_DIR=${PROC_DIR}/TMP
mkdir -p ${TMP_DIR}
#	Credentials
read -r -p "Please type your ESA Scihub Username:" USERNAME
read -s -p "Please type your ESA Scihub Password:" PW
echo ""
echo "Getting the inventory data"

# Product Filters
PRODUCT_TYPE=GRD
POL_MODE=VH

# get the footprint from the AOI shapefile 
#ogr2ogr -f CSV ${TMP_DIR}/tmp_AOI_WKT.csv $2 -lco GEOMETRY=AS_WKT
#AOI=`grep POLYGON ${TMP_DIR}/tmp_AOI_WKT.csv | awk -F "))" $'{print $1}'`
#echo $AOI
LAYER=`ogrinfo $2 | grep 1: | awk $'{print $2}'`
X_MIN=`ogrinfo $2 $LAYER | grep Extent | awk -F '(' $'{print $2}' | awk -F ','  $'{print $1}'`
X_MAX=`ogrinfo $2 $LAYER | grep Extent | awk -F '(' $'{print $3}' | awk -F ','  $'{print $1}'`
Y_MIN=`ogrinfo $2 $LAYER | grep Extent | awk -F ',' $'{print $2}' | awk -F ')' $'{print $1}'`
Y_MAX=`ogrinfo $2 $LAYER | grep Extent | awk -F ',' $'{print $3}' | awk -F ')' $'{print $1}'`
AOI="POLYGON(($X_MIN$Y_MIN, $X_MIN$Y_MAX, $X_MAX$Y_MAX, $X_MAX$Y_MIN, $X_MIN$Y_MIN ))"
#echo $AOI

# get the OpenSearch result
echo "data inventory from scihub server"
#wget --no-check-certificate --user=${USERNAME} --password=${PASSWORD} -O ${TMP_DIR}/datalist "https://scihub.esa.int/dhus//search?q=producttype:${PRODUCT_TYPE}+AND+polarisationMode:${POL_MODE}+AND+( footprint:\"Intersects(POLYGON((79.6519320000000 9.0000000000000,81.0000000000000 9.0000000000000,81.0000000000000 5.0000000000000,79.6519320000000 5.0000000000000,79.6519320000000 9.0000000000000 )))\")&rows=10000&start=0"

wget --no-check-certificate --user=${USERNAME} --password=${PASSWORD} -O ${TMP_DIR}/datalist "https://scihub.esa.int/dhus//search?q=producttype:${PRODUCT_TYPE}+AND+polarisationMode:${POL_MODE}+AND+( footprint:\"Intersects($AOI)\")&rows=10000&start=0"

# get the important info out of the xml result
xml_grep title ${TMP_DIR}/datalist --text_only | tail -n +2 > ${TMP_DIR}/scenes
xml_grep title ${TMP_DIR}/datalist --text_only | tail -n +2 | cut -c 18-25 > ${TMP_DIR}/dates
xml_grep id ${TMP_DIR}/datalist --text_only | tail -n +2 > ${TMP_DIR}/uuid
xml_grep str ${TMP_DIR}/datalist --text_only | grep "POLYGON ((" | sed 's|POLY|\"POLY|g' | sed 's|))|))"|g' > ${TMP_DIR}/polys
xml_grep str ${TMP_DIR}/datalist --text_only | grep "orbitDirection" > ${TMP_DIR}/orbit
xml_grep str ${TMP_DIR}/datalist --text_only | grep "swathidentifier" > ${TMP_DIR}/swath
	 

# write header
echo "Scene_ID,Product_ID,Date,Swath,Orbit_Dir,WKTGeom" > ${TMP_DIR}/wkt.csv
echo '"String(68)","String(37)","Integer(8)","String(5)","String(11)","String"' > ${TMP_DIR}/wkt.csvt

# write data
paste -d "," ${TMP_DIR}/scenes ${TMP_DIR}/uuid ${TMP_DIR}/dates ${TMP_DIR}/swath ${TMP_DIR}/orbit ${TMP_DIR}/polys > ${TMP_DIR}/data

cat ${TMP_DIR}/data >> ${TMP_DIR}/wkt.csv

mkdir -p ${PROC_DIR}/S1
mkdir -p ${PROC_DIR}/S1/ZIP
mkdir -p ${PROC_DIR}/S1/Inventory
INV=${PROC_DIR}/S1/Inventory

# write a shapefile of coverage
echo "<OGRVRTDataSource>" > ${TMP_DIR}/wkt.vrt
echo "	<OGRVRTLayer name=\"wkt\">" >> ${TMP_DIR}/wkt.vrt
echo "   	<SrcDataSource>${TMP_DIR}/wkt.csv</SrcDataSource>" >> ${TMP_DIR}/wkt.vrt
echo "   	<GeometryType>wkbPolygon</GeometryType>" >> ${TMP_DIR}/wkt.vrt
echo "		<LayerSRS>WGS84</LayerSRS>"  >> ${TMP_DIR}/wkt.vrt
echo "		<GeometryField encoding=\"WKT\" field=\"WKTGeom\"> </GeometryField >" >> ${TMP_DIR}/wkt.vrt
echo "	</OGRVRTLayer>" >> ${TMP_DIR}/wkt.vrt
echo "</OGRVRTDataSource>" >> ${TMP_DIR}/wkt.vrt

cd ${PROC_DIR}
# convert to final schapefile
ogr2ogr -f "Esri Shapefile" ${INV}/wkt.shp ${TMP_DIR}/wkt.vrt

while read line; do 

	# get the data via the UUID
   SCENE=`echo $line | awk -F "," $'{print $1}'`			  
	UUID=`echo $line | awk -F "," $'{print $2}'`		


	echo "Downloading $SCENE"
	DL_ADDRESS='https://scihub.esa.int/dhus/odata/v1/Products('"'${UUID}'"')/$value'
#	echo "wget --no-check-certificate --user="${USERNAME}" --password="${PASSWORD}" "${DL_ADDRESS}""

#	echo "Moving $SCENE to ${PROC_DIR}/S1/ZIP"
#	mv '$value' ${PROC_DIR}/S1/ZIP/${SCENE}.zip

done  < ${TMP_DIR}/data

#rm -rf ${TMP_DIR}
