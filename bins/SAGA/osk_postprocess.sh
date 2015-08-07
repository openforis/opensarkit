#! /bin/bash


#----------------------------------------------------------------------
#	Mosaicing script
#
#	Dependencies:
#
#		- SAGA GIS (> 2.1.4)
#		- gdal-tools
#		- S1TBX
#
#
#----------------------------------------------------------------------

# TMP sourcing for Sepal env.
source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash
source /home/avollrath/github/OpenSARKit/OpenSARKit_source.bash

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------
	
# 	0.1 Check for right usage
if [ "$#" != "2" ]; then
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "Usage: osk_postprocess </path/to/mosaic/sat/tracks> </path/to/dem>"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "This script: mosaics primarily merged Satellite Tracks (i.e. output of osk_SENSOR_merge_path)"
  echo -e "	- mosaics primarily merged Satellite Tracks (i.e. output of osk_SENSOR_merge_path) [SAGA GIS]"
  echo -e "	- filters the Gamma0 channels with a multi-directional filter (Lee et al. 1998) [SAGA GIS]"
  echo -e "	- calculates second order statistics for Texture measurements (i.e. GLCM Mean, GLCM Variance) [Sentinel Toolbox]"
  echo -e "	- outputs all files with sam extent and resolution in GeoTiff format ready for RSGISLIB segmentation [gdal]"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "The path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "This script: mosaics primarily merged Satellite Tracks (i.e. output of osk_SENSOR_merge_path)"
  echo -e "	- mosaics primarily merged Satellite Tracks (i.e. output of osk_SENSOR_merge_path) [SAGA GIS]"
  echo -e "	- filters the Gamma0 channels with a multi-directional filter (Lee et al. 1998) [SAGA GIS]"
  echo -e "	- calculates second order statistics for Texture measurements (i.e. GLCM Mean, GLCM Variance) [Sentinel Toolbox]"
  echo -e "	- outputs all files with sam extent and resolution in GeoTiff format ready for RSGISLIB segmentation [gdal]"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo "Processing folder: ${PROC_DIR}"
  echo "Output folder: ${PROC_DIR}/../FINAL_MOSAIC"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
fi

# set up paths
cd ${PROC_DIR}
TMP_DIR=${PROC_DIR}/TMP
FINAL=${PROC_DIR}/../FINAL_MOSAIC
mkdir -p ${FINAL}
mkdir -p $TMP_DIR

DEM=$2
# Number of CPUs (for SAGA GIS)
CPU=`lscpu | grep "CPU(s):" | awk $'{print $2}' | head -1`


#------------------------------------------------------------
# reduce range from -30 to 5db for HH channel and mosaicing
#------------------------------------------------------------

echo "Reducing range from -30 to 5db for HH channel"
for line in `ls -1 *Gamma0_HH_db.sdat`;do 
	gdal_calc.py -A $line --outfile ${TMP_DIR}/tmp1.tif --calc="A*(A>-30)" --NoDataValue=-99999
	gdal_calc.py -A ${TMP_DIR}/tmp1.tif  --outfile ${TMP_DIR}/tmp2.tif --calc="A*(A<5)" --NoDataValue=-99999
	gdal_translate -of SAGA ${TMP_DIR}/tmp2.tif ${TMP_DIR}/end_$line
	rm -f ${TMP_DIR}/tmp*
done 

echo "Mosaicing the HH channel"
if [[ `ls -1 ${TMP_DIR}/end*Gamma0_HH_db.sgrd | wc -l` == 1 ]];then
	mv ${TMP_DIR}/end*sgrd ${TMP_DIR}/GAMMA0_HH_db_mosaic.sgrd
	mv ${TMP_DIR}/end*mgrd ${TMP_DIR}/GAMMA0_HH_db_mosaic.mgrd
	mv ${TMP_DIR}/end*sdat ${TMP_DIR}/GAMMA0_HH_db_mosaic.sdat
	mv ${TMP_DIR}/end*prj ${TMP_DIR}/GAMMA0_HH_db_mosaic.prj
else
	LIST_GAMMA_HH=`ls -1 ${TMP_DIR}/end*Gamma0_HH_db.sgrd | tr '\n' ';'`
	saga_cmd -f=r -c=${CPU} grid_tools 3 -GRIDS:${LIST_GAMMA_HH} -TYPE:7 -OVERLAP:6 -BLEND_DIST:10	 -MATCH:1 -TARGET_OUT_GRID:${TMP_DIR}/GAMMA0_HH_db_mosaic.sgrd
	rm -rf ${TMP_DIR}/end*
fi 


echo "Reducing range from -30 to 5db for HV channel"
for line in `ls -1 *Gamma0_HV_db.sdat`;do 
	gdal_calc.py -A $line --outfile ${TMP_DIR}/tmp1.tif --calc="A*(A>-30)" --NoDataValue=-99999
	gdal_calc.py -A ${TMP_DIR}/tmp1.tif  --outfile ${TMP_DIR}/tmp2.tif --calc="A*(A<5)" --NoDataValue=-99999
	gdal_translate -of SAGA ${TMP_DIR}/tmp2.tif ${TMP_DIR}/end_$line
	rm -f ${TMP_DIR}/tmp*
done 

echo "Mosaicing the HV channel"
if [[ `ls -1 ${TMP_DIR}/end*Gamma0_HV_db.sgrd | wc -l` == 1 ]];then
	mv ${TMP_DIR}/end*sgrd ${TMP_DIR}/GAMMA0_HV_db_mosaic.sgrd
	mv ${TMP_DIR}/end*mgrd ${TMP_DIR}/GAMMA0_HV_db_mosaic.mgrd
	mv ${TMP_DIR}/end*sdat ${TMP_DIR}/GAMMA0_HV_db_mosaic.sdat
	mv ${TMP_DIR}/end*prj ${TMP_DIR}/GAMMA0_HV_db_mosaic.prj

else
	LIST_GAMMA_HV=`ls -1 ${TMP_DIR}/end*Gamma0_HV_db.sgrd | tr '\n' ';'`
	saga_cmd -f=r -c=${CPU} grid_tools 3 -GRIDS:${LIST_GAMMA_HV} -TYPE:7 -OVERLAP:6 -BLEND_DIST:10 -MATCH:1 -TARGET_OUT_GRID:${TMP_DIR}/GAMMA0_HV_db_mosaic.sgrd
	rm -rf ${TMP_DIR}/end*
fi

echo "--------------------------------------------------------------------------------------------------"
echo " Calculate second order statistic Texture measurements (GLCMMean, GLCMVariance) for HH channel"
echo "--------------------------------------------------------------------------------------------------"
# transfer from SAGA to tif format
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -srcnodata -99999 -dstnodata 0 ${TMP_DIR}/GAMMA0_HH_db_mosaic.sdat ${TMP_DIR}/GAMMA0_HH_db_mosaic2.tif

# define path/name of output
INPUT_HH=${TMP_DIR}/GAMMA0_HH_db_mosaic2.tif
INPUT_HV=${TMP_DIR}/GAMMA0_HV_db_mosaic2.tif

OUTPUT_TEXTURE_HH=${TMP_DIR}/TEXTURE_HH.dim
OUTPUT_TEXTURE_HV=${TMP_DIR}/TEXTURE_HV.dim

# Write new xml graph and substitute input and output files
cp ${S1TBX_GRAPHS}/Generic_Texture.xml ${TMP_DIR}/TEXTURE_HH.xml
	
# insert Input file path into processing chain xml
sed -i "s|INPUT_TR|${INPUT_HH}|g" ${TMP_DIR}/TEXTURE_HH.xml
# insert Input file path into processing chain xml
sed -i "s|OUTPUT_TR|${OUTPUT_TEXTURE_HH}|g" ${TMP_DIR}/TEXTURE_HH.xml

#echo "Calculate GLCM Texture measurements for HH channel"
sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml 2>&1 | tee  ${TMP_DIR}/tmplog

# in case it fails try a second time	
if grep -q Error ${TMP_DIR}/tmplog; then 	
	echo "2nd try"
	rm -rf ${TMP_DIR}/TEXTURE_HH.dim ${TMP_DIR}/TEXTURE_HH.data
	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml
fi

echo "--------------------------------------------------------------------------------------------------"
echo " Calculate second order statistic Texture measurements (GLCMMean, GLCMVariance) for HV channel"
echo "--------------------------------------------------------------------------------------------------"
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -srcnodata -99999 -dstnodata 0 ${TMP_DIR}/GAMMA0_HV_db_mosaic.sdat ${TMP_DIR}/GAMMA0_HV_db_mosaic2.tif
# Write new xml graph and substitute input and output files
cp ${S1TBX_GRAPHS}/Generic_Texture.xml ${TMP_DIR}/TEXTURE_HV.xml
	
# insert Input file path into processing chain xml
sed -i "s|INPUT_TR|${INPUT_HV}|g" ${TMP_DIR}/TEXTURE_HV.xml
# insert Input file path into processing chain xml
sed -i "s|OUTPUT_TR|${OUTPUT_TEXTURE_HV}|g" ${TMP_DIR}/TEXTURE_HV.xml

echo "Calculate GLCM Texture measurements for HV channel"
sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HV.xml 2>&1 | tee  ${TMP_DIR}/tmplog

# in case it fails try a second time	
if grep -q Error ${TMP_DIR}/tmplog; then 	
	echo "2nd try"
	rm -rf ${TMP_DIR}/TEXTURE_HV.dim ${TMP_DIR}/TEXTURE_HV.data
	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HV.xml
fi

echo "------------------------------------------------------------"
echo " Multi-directional filtering of the Gamma0 HH channel"
echo "------------------------------------------------------------"
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of SAGA -srcnodata 0 -dstnodata -99999 ${TMP_DIR}/TEXTURE_HH.data/band_1.img ${TMP_DIR}/TEXTURE_HH.data/band_1_saga.sdat
saga_cmd -f=r -c=${CPU} grid_filter 3 -INPUT:${TMP_DIR}/TEXTURE_HH.data/band_1_saga.sgrd -RESULT:${TMP_DIR}/GAMMA0_HH_db_mosaic_filtered.sgrd -NOISE_ABS:5 -NOISE_REL:3 -METHOD:1

echo "------------------------------------------------------------"
echo " Multi-directional filtering of the Gamma0 HV channel"
echo "------------------------------------------------------------"
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of SAGA -srcnodata 0 -dstnodata -99999 ${TMP_DIR}/TEXTURE_HV.data/band_1.img ${TMP_DIR}/TEXTURE_HV.data/band_1_saga.sdat
saga_cmd -f=r -c=${CPU} grid_filter 3 -INPUT:${TMP_DIR}/TEXTURE_HV.data/band_1_saga.sgrd -RESULT:${TMP_DIR}/GAMMA0_HV_db_mosaic_filtered.sgrd -NOISE_ABS:5 -NOISE_REL:3 -METHOD:1

echo "------------------------------------------------------------"
echo " Calculate HH/HV ratio"
echo "------------------------------------------------------------"
#saga_cmd grid_calculus 1 -GRIDS:${FINAL}/GAMMA0_HH_db_mosaic.sdat -XGRIDS:${FINAL}/GAMMA0_HV_db_mosaic.sdat -RESULT:${FINAL}/HH_HV_db_mosaic.sdat -FORMULA:"a / b"
saga_cmd -f=r -c=${CPU} grid_calculus 1 -GRIDS:${TMP_DIR}/GAMMA0_HH_db_mosaic_filtered.sgrd -XGRIDS:${TMP_DIR}/GAMMA0_HV_db_mosaic_filtered.sgrd -RESULT:${TMP_DIR}/HH_HV_db_mosaic_filtered.sdat -FORMULA:"a / b"


gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata -99999 -dstnodata 0 -tr 0.000277778 0.000277778 ${TMP_DIR}/GAMMA0_HH_db_mosaic_filtered.sdat ${TMP_DIR}/1_Gamma0_HH.tif
# get the common area of DEM and outputfiles
XMIN=`osk_intersect_raster.py -a ${TMP_DIR}/1_Gamma0_HH.tif -b $DEM | awk -F ',' $'{print$1}' | cut -c 2-`
XMAX=`osk_intersect_raster.py -a ${TMP_DIR}/1_Gamma0_HH.tif -b $DEM | awk -F ',' $'{print$3}'`
YMAX=`osk_intersect_raster.py -a ${TMP_DIR}/1_Gamma0_HH.tif -b $DEM | awk -F ',' $'{print$2}'`
YMIN=`osk_intersect_raster.py -a ${TMP_DIR}/1_Gamma0_HH.tif -b $DEM | awk -F ',' $'{print$4}' | rev | cut -c 2-| rev`

gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata -99999 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 ${TMP_DIR}/GAMMA0_HH_db_mosaic_filtered.sdat ${FINAL}/01_Gamma0_HH.tif
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata -99999 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 ${TMP_DIR}/GAMMA0_HV_db_mosaic_filtered.sdat ${FINAL}/02_Gamma0_HV.tif
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata -99999 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 ${TMP_DIR}/HH_HV_db_mosaic_filtered.sdat ${FINAL}/03_HH_HV_ratio.tif
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata 0 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 ${TMP_DIR}/TEXTURE_HH.data/GLCMMean.img ${FINAL}/04_GLCMMean_HH.tif
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata 0 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 ${TMP_DIR}/TEXTURE_HH.data/GLCMVariance.img ${FINAL}/05_GLCMVariance_HH.tif
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata 0 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 ${TMP_DIR}/TEXTURE_HV.data/GLCMMean.img ${FINAL}/06_GLCMMean_HV.tif
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -t_srs EPSG:4326 -srcnodata 0 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 ${TMP_DIR}/TEXTURE_HV.data/GLCMVariance.img ${FINAL}/07_GLCMVariance_HV.tif
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -of GTiff -ot Float32 -t_srs EPSG:4326 -srcnodata -99999 -dstnodata 0 -te $XMIN $YMIN $XMAX $YMAX -tr 0.000277778 0.000277778 $DEM ${FINAL}/08_DEM_height.tif
# write world file (we will need for segmentation)
listgeo -tfw ${FINAL}/01_Gamma0_HH.tif
mv ${FINAL}/01_Gamma0_HH.tfw ${FINAL}/generic.tfw

# create slope and aspect layers
# mask for no data 
gdaldem slope -s 111120 ${FINAL}/08_DEM_height.tif ${FINAL}/09_DEM_slope.tif
gdaldem aspect ${FINAL}/08_DEM_height.tif ${FINAL}/10_DEM_aspect.tif

gdalbuildvrt -separate -srcnodata 0 stack.vrt ${FINAL}/*.tif
# remove temp files
#rm -rf ${TMP_DIR}

echo "----------------------------------"
echo " Processing succesfully finished"
echo "----------------------------------"
