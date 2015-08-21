#! /bin/bash

if [ "$#" != "2" ]; then  
  echo -e "Usage: osk_mosaic </path/to/mosaic/sat/tracks> </path/to/AOI>"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  AOI=$2	
fi

cd ${PROC_DIR}
TMP_DIR=${PROC_DIR}/TMP
mkdir -p ${TMP_DIR}
rm ${TMP_DIR}/list
FINAL_DIR=${PROC_DIR}/Final_Mosaic
mkdir -p ${FINAL_DIR}
CPU=`lscpu | grep "CPU(s):" | awk $'{print $2}' | head -1`

for FILE in `ls -1 *HH*sdat`;do

	LONG=`gdalinfo $FILE | grep Origin | awk -F "(" $'{print $2}' | awk -F "," $'{print $1}'`

	echo $LONG $FILE >> ${TMP_DIR}/list
	sort -n ${TMP_DIR}/list > ${TMP_DIR}/list_sort

done	

i=1	
sed -i 's|.sdat|.sgrd|g' ${TMP_DIR}/list_sort
MAX_LINE=`cat ${TMP_DIR}/list_sort | wc -l`


while read LINE; do

	DATA=`echo ${LINE} | awk $'{print $2}'`
	
	GRID2=${DATA}
		
	echo "Do resampling to 0.0005"
	saga_cmd -c=${CPU} grid_tools 0 -INPUT ${GRID2} -KEEP_TYPE:1 -TARGET_USER_SIZE:0.00027778 -SCALE_UP_METHOD:1 -SCALE_DOWN_METHOD:1 -TARGET_OUT_GRID:${TMP_DIR}/$DATA-res.sgrd
	echo "Cut to Boundaries"
	saga_cmd -c=${CPU} shapes_grid 7 -OUTPUT ${TMP_DIR}/$DATA-res-cli.sgrd -INPUT ${TMP_DIR}/$DATA-res.sgrd -POLYGONS $AOI -NODATA 1
	rm -rf ${TMP_DIR}/*-res.*
	echo "Reclassify"
	saga_cmd -c=${CPU} grid_tools 15 -INPUT ${TMP_DIR}/$DATA-res-cli.sgrd -RESULT ${TMP_DIR}/$DATA-res-cli-rec.sgrd -METHOD 1 -MIN -1000 -MAX 0.001 -RNEW 0.001 
	rm -rf ${TMP_DIR}/*-res-cli.*
	echo "Reclassify"
	saga_cmd -c=${CPU} grid_tools 15 -INPUT ${TMP_DIR}/$DATA-res-cli-rec.sgrd -RESULT ${TMP_DIR}/$DATA-res-cli-rec2.sgrd -METHOD 1 -MIN 1 -MAX 1000 -RNEW 1
	rm -rf ${TMP_DIR}/*-res-cli-rec.*
#	saga_cmd grid_calculus 1 -GRIDS:"${TMP_DIR}/$DATA-res-cli-rec2.sgrd" -RESULT:"${TMP_DIR}/$DATA-dB.sgrd" -FORMULA:"10*log(a)"	
	#rm -rf ${TMP_DIR}/*-res-cli-rec2.*

done < ${TMP_DIR}/list_sort

cd ${TMP_DIR}
#LIST_HH=`ls -1 *-dB.sgrd | tr '\n' ';'| rev|cut -c 2-|rev`
#saga_cmd -c=${CPU} grid_tools 3 -GRIDS:${LIST_HH} -TYPE:7 -OVERLAP:4 -BLEND_DIST:10 -MATCH:1 -TARGET_OUT_GRID:${FINAL_DIR}/GAMMA0_HH_db_mosaic.sgrd

LIST_HH=`ls -1 *-rec2.sgrd | tr '\n' ';'| rev|cut -c 2-|rev`
saga_cmd -c=${CPU} grid_tools 3 -GRIDS:${LIST_HH} -TYPE:7 -OVERLAP:4 -BLEND_DIST:10 -MATCH:0 -TARGET_OUT_GRID:${TMP_DIR}/GAMMA0_HH_mosaic.sgrd

#saga_cmd -f=r -c=${CPU} grid_filter 3 -INPUT:${TMP_DIR}/GAMMA0_HH_mosaic.sgrd -RESULT:${FINAL_DIR}/GAMMA0_HH_mosaic_filtered.sgrd -NOISE_ABS:5000 -NOISE_REL:5000 -METHOD:1

rm -rf ${TMP_DIR}/*
cd ${PROC_DIR}
for FILE in `ls -1 *HV*sdat`;do

	LONG=`gdalinfo $FILE | grep Origin | awk -F "(" $'{print $2}' | awk -F "," $'{print $1}'`

	echo $LONG $FILE >> ${TMP_DIR}/list
	sort -n ${TMP_DIR}/list > ${TMP_DIR}/list_sort

done	

i=1	
sed -i 's|.sdat|.sgrd|g' ${TMP_DIR}/list_sort
MAX_LINE=`cat ${TMP_DIR}/list_sort | wc -l`


while read LINE; do

	DATA=`echo ${LINE} | awk $'{print $2}'`
	
	GRID2=${DATA}
		
	echo "Do resampling to 0.0005"
	saga_cmd -c=${CPU} grid_tools 0 -INPUT ${GRID2} -KEEP_TYPE:1 -TARGET_USER_SIZE:0.00027778 -SCALE_UP_METHOD:1 -SCALE_DOWN_METHOD:1 -TARGET_OUT_GRID:${TMP_DIR}/$DATA-res.sgrd
	echo "Cut to Boundaries"
	saga_cmd -c=${CPU} shapes_grid 7 -OUTPUT ${TMP_DIR}/$DATA-res-cli.sgrd -INPUT ${TMP_DIR}/$DATA-res.sgrd -POLYGONS $AOI -NODATA 1
	rm -rf ${TMP_DIR}/*-res.*
	echo "Reclassify"
	saga_cmd -c=${CPU} grid_tools 15 -INPUT ${TMP_DIR}/$DATA-res-cli.sgrd -RESULT ${TMP_DIR}/$DATA-res-cli-rec.sgrd -METHOD 1 -MIN -1000 -MAX 0.001 -RNEW 0.001 
	rm -rf ${TMP_DIR}/*-res-cli.*
	echo "Reclassify"
	saga_cmd -c=${CPU} grid_tools 15 -INPUT ${TMP_DIR}/$DATA-res-cli-rec.sgrd -RESULT ${TMP_DIR}/$DATA-res-cli-rec2.sgrd -METHOD 1 -MIN 1 -MAX 1000 -RNEW 1
	rm -rf ${TMP_DIR}/*-res-cli-rec.*
#	saga_cmd grid_calculus 1 -GRIDS:"${TMP_DIR}/$DATA-res-cli-rec2.sgrd" -RESULT:"${TMP_DIR}/$DATA-dB.sgrd" -FORMULA:"10*log(a)"	
	#rm -rf ${TMP_DIR}/*-res-cli-rec2.*

done < ${TMP_DIR}/list_sort

cd ${TMP_DIR}
#LIST_HH=`ls -1 *-dB.sgrd | tr '\n' ';'| rev|cut -c 2-|rev`
#saga_cmd -c=${CPU} grid_tools 3 -GRIDS:${LIST_HH} -TYPE:7 -OVERLAP:4 -BLEND_DIST:10 -MATCH:1 -TARGET_OUT_GRID:${FINAL_DIR}/GAMMA0_HH_db_mosaic.sgrd

LIST_HV=`ls -1 *-rec2.sgrd | tr '\n' ';'| rev|cut -c 2-|rev`
saga_cmd -c=${CPU} grid_tools 3 -GRIDS:${LIST_HV} -TYPE:7 -OVERLAP:4 -BLEND_DIST:10 -MATCH:0 -TARGET_OUT_GRID:${TMP_DIR}/GAMMA0_HV_mosaic.sgrd

#saga_cmd -f=r -c=${CPU} grid_filter 3 -INPUT:${TMP_DIR}/GAMMA0_HV_mosaic.sgrd -RESULT:${FINAL_DIR}/GAMMA0_HV_mosaic_filtered.sgrd -NOISE_ABS:5000 -NOISE_REL:5000 -METHOD:1

saga_cmd -f=r -c=${CPU} grid_calculus 1 -GRIDS:${FINAL_DIR}/GAMMA0_HH_mosaic_filtered.sgrd -XGRIDS:${FINAL_DIR}/GAMMA0_HV_mosaic.sgrd -RESULT:${FINAL_DIR}/HH_HV_mosaic.sgrd -FORMULA:"a / b"
