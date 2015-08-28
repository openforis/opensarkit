	#! /bin/bash

# segmentation


#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------
	
# 	0.1 Check for right usage
if [ "$#" != "1" ]; then
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "Usage: osk_segmentation.sh </path/to/mosaic/>"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "This script:"
  echo -e "	- creates an Image Stack in KEA Format of the output of osk_postprocess [RSGISLIB]"
  echo -e "	- Applies a Segmentation based on Shepard et al. 2013 [RSGISLIB]"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "The path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "This script:"
  echo -e "	- creates an Image Stack in KEA Format of the output of osk_postprocess [RSGISLIB]"
  echo -e "	- Applies a Segmentation based on Shepard et al. 2013 [RSGISLIB]"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo -e "The path will be your Project folder!"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
  echo "Processing folder: ${PROC_DIR}"
  echo "Output folder: ${PROC_DIR}/../FINAL_MOSAIC"
  echo -e "------------------------------------------------------------------------------------------------------------------------"
fi

export PATH="~/miniconda/bin:$PATH"
export GDAL_DRIVER_PATH=~/miniconda/lib/gdalplugins
export GDAL_DATA=~/miniconda/share/gdal

TMP_DIR=${PROC_DIR}/TMP
mkdir -p ${TMP_DIR}

ls -1 ${PROC_DIR}/*.tif > ${TMP_DIR}/list

STACK=${PROC_DIR}/outStack.kea
osk_stacking.py -i ${TMP_DIR}/list -o $STACK

# Segmentation
rsgislibsegmentation.py --input $STACK --output ${TMP_DIR}/segmentation_15_25.kea --outmeanimg ${TMP_DIR}/segmentation.mean.15_25.kea -t ${TMP_DIR} --numclusters 15 --minpxls 25
rsgislibsegmentation.py --input $STACK --output ${TMP_DIR}/segmentation_15_100.kea --outmeanimg ${TMP_DIR}/segmentation.mean.15_100.kea -t ${TMP_DIR} --numclusters 15 --minpxls 100
rsgislibsegmentation.py --input $STACK --output ${TMP_DIR}/segmentation_15_250.kea --outmeanimg ${TMP_DIR}/segmentation.mean.15_250.kea -t ${TMP_DIR} --numclusters 15 --minpxls 250


for i in {1..10}; do  # number of bands should be extracted from the stack itself
	gdal_translate -of GTiff -a_nodata 0 -a_srs EPSG:4326 HDF5:"${TMP_DIR}/segmentation.mean.15_25.kea"://BAND${i}/DATA ${TMP_DIR}/band_15_25_${i}.tif
	cp ${PROC_DIR}/generic.tfw ${TMP_DIR}/band_15_25_${i}.tfw
	
	gdal_translate -of GTiff -a_nodata 0 -a_srs EPSG:4326 HDF5:"${TMP_DIR}/segmentation.mean.15_100.kea"://BAND${i}/DATA ${TMP_DIR}/band_15_100_${i}.tif
	cp ${PROC_DIR}/generic.tfw ${TMP_DIR}/band_15_100_${i}.tfw

	gdal_translate -of GTiff -a_nodata 0 -a_srs EPSG:4326 HDF5:"${TMP_DIR}/segmentation.mean.15_250.kea"://BAND${i}/DATA ${TMP_DIR}/band_15_250_${i}.tif
	cp ${PROC_DIR}/generic.tfw ${TMP_DIR}/band_15_250_${i}.tfw
done

SEG_15_25=${PROC_DIR}/Seg_15_25
SEG_15_100=${PROC_DIR}/Seg_15_100
SEG_15_250=${PROC_DIR}/Seg_15_250

mkdir -p  ${SEG_15_25}
mkdir -p  ${SEG_15_100}
mkdir -p  ${SEG_15_250}

gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_1.tif ${SEG_15_25}/01_Gamma0.HH.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_2.tif ${SEG_15_25}/02_Gamma0.HV.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_3.tif ${SEG_15_25}/03_HH.HV.ratio.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_4.tif ${SEG_15_25}/04_GLCMMean.HH.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_5.tif ${SEG_15_25}/05_GLCMMean.HV.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_6.tif ${SEG_15_25}/06_GLCMVariance.HH.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_7.tif ${SEG_15_25}/07_GLCMVariance.HV.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_8.tif ${SEG_15_25}/08_DEM_height.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_9.tif ${SEG_15_25}/09_DEM_slope.seg.15_25.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_25_10.tif ${SEG_15_25}/10_DEM_aspect.seg.15_25.tif
gdalbuildvrt -separate -srcnodata 0 ${SEG_15_25}/stack.seg.15.25.vrt ${SEG_15_25}/* 

gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_1.tif ${SEG_15_100}/01_Gamma0.HH.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_2.tif ${SEG_15_100}/02_Gamma0.HV.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_3.tif ${SEG_15_100}/03_HH.HV.ratio.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_4.tif ${SEG_15_100}/04_GLCMMean.HH.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_5.tif ${SEG_15_100}/05_GLCMMean.HV.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_6.tif ${SEG_15_100}/06_GLCMVariance.HH.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_7.tif ${SEG_15_100}/07_GLCMVariance.HV.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_8.tif ${SEG_15_100}/08_DEM_height.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_9.tif ${SEG_15_100}/09_DEM_slope.seg.15_100.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_100_10.tif ${SEG_15_100}/10_DEM_aspect.seg.15_100.tif
gdalbuildvrt -separate -srcnodata 0 ${SEG_15_100}/stack.seg.15.100.vrt ${SEG_15_100}/*

gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_1.tif ${SEG_15_250}/01_Gamma0.HH.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_2.tif ${SEG_15_250}/02_Gamma0.HV.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_3.tif ${SEG_15_250}/03_HH.HV.ratio.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_4.tif ${SEG_15_250}/04_GLCMMean.HH.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_5.tif ${SEG_15_250}/05_GLCMMean.HV.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_6.tif ${SEG_15_250}/06_GLCMVariance.HH.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_7.tif ${SEG_15_250}/07_GLCMVariance.HV.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_8.tif ${SEG_15_250}/08_DEM_height.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_9.tif ${SEG_15_250}/09_DEM_slope.seg.15_250.tif
gdal_translate -a_nodata 0 -a_srs EPSG:4326 ${TMP_DIR}/band_15_250_10.tif ${SEG_15_250}/10_DEM_aspect.seg.15_250.tif
gdalbuildvrt -separate -srcnodata 0 ${SEG_15_250}/stack.seg.15.250.vrt ${SEG_15_250}/*

rm -rf ${TMP_DIR}
