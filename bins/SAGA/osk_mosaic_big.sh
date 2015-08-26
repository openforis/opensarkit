#! /bin/bash



PROC_DIR=/media/avollrath/OpenSARdata/Zambia/L1.5/FBD/PATH_MOSAICS

AOI=/media/avollrath/OpenSARdata/Zambia/Adm/ZMB_adm/ZMB_adm0.shp
cd ${PROC_DIR}
TMP_DIR=${PROC_DIR}/TMP
mkdir -p ${TMP_DIR}
rm ${TMP_DIR}/list
FINAL_DIR=${PROC_DIR}/Final_Mosaic
mkdir -p ${FINAL_DIR}
CPU=`lscpu | grep "CPU(s):" | awk $'{print $2}' | head -1`

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

	if [ $i == 1 ];then
		echo "Merging Paths"
		echo $i
		echo $DATA > ${TMP_DIR}/tmp1
	
	elif [ $i == 2 ];then

		echo $i
		#echo $LINE

		GRID1=`cat ${TMP_DIR}/tmp1`
		GRID2=${DATA}
		
		saga_cmd grid_tools 0 -INPUT ${GRID1} -KEEP_TYPE:1 -TARGET_USER_SIZE:0.0005 -SCALE_UP_METHOD:1 -SCALE_DOWN_METHOD:1 -TARGET_OUT_GRID:${TMP_DIR}/$DATA-1.sgrd
		saga_cmd grid_tools 0 -INPUT ${GRID2} -KEEP_TYPE:1 -TARGET_USER_SIZE:0.0005 -SCALE_UP_METHOD:1 -SCALE_DOWN_METHOD:1 -TARGET_OUT_GRID:${TMP_DIR}/$DATA-2.sgrd

		saga_cmd -c=${CPU} shapes_grid 7 -OUTPUT ${TMP_DIR}/$DATA-1_1.sgrd -INPUT ${TMP_DIR}/$DATA-1.sgrd -POLYGONS $AOI -NODATA 1
		saga_cmd -c=${CPU} shapes_grid 7 -OUTPUT ${TMP_DIR}/$DATA-2_1.sgrd -INPUT ${TMP_DIR}/$DATA-2.sgrd -POLYGONS $AOI -NODATA 1

		saga_cmd -c=${CPU} grid_tools 3 -GRIDS:"${TMP_DIR}/$DATA-1_1.sgrd;${TMP_DIR}/$DATA-2_1.sgrd" -TYPE:7 -OVERLAP:6 -BLEND_DIST:10 -MATCH:1 -TARGET_OUT_GRID:${TMP_DIR}/out_$i.sgrd

	elif [ $i == $MAX_LINE ];then

		echo $i
		#echo $LINE
	
		GRID1=${TMP_DIR}/out_$j.sgrd
		GRID2=${DATA}

		saga_cmd grid_tools 0 -INPUT ${GRID2} -KEEP_TYPE:1 -TARGET_USER_SIZE:0.0005 -SCALE_UP_METHOD:1 -SCALE_DOWN_METHOD:1 -TARGET_OUT_GRID:${TMP_DIR}/$DATA-2.sgrd
		saga_cmd -c=${CPU} shapes_grid 7 -OUTPUT ${TMP_DIR}/$DATA-2_1.sgrd -INPUT ${TMP_DIR}/$DATA-2.sgrd -POLYGONS $AOI -NODATA 1
		
		saga_cmd -c=${CPU} grid_tools 3 -GRIDS:"${GRID1};${TMP_DIR}/${DATA}-2_1.sgrd" -TYPE:7 -OVERLAP:6 -BLEND_DIST:10 -MATCH:1 -TARGET_OUT_GRID:${FINAL_DIR}/final_mosaic.sgrd

	else

		echo $i
		#echo $LINE

		GRID1=${TMP_DIR}/out_$j.sgrd
		GRID2=${DATA}

		saga_cmd grid_tools 0 -INPUT ${GRID2} -KEEP_TYPE:1 -TARGET_USER_SIZE:0.0005 -SCALE_UP_METHOD:1 -SCALE_DOWN_METHOD:1 -TARGET_OUT_GRID:${TMP_DIR}/$DATA-2.sgrd
		saga_cmd -c=${CPU} shapes_grid 7 -OUTPUT ${TMP_DIR}/${DATA}-2_1.sgrd -INPUT ${TMP_DIR}/$DATA-2.sgrd -POLYGONS $AOI -NODATA 1

		saga_cmd -c=${CPU} grid_tools 3 -GRIDS:"${GRID1};${TMP_DIR}/${DATA}-2_1.sgrd" -TYPE:7 -OVERLAP:6 -BLEND_DIST:10 -MATCH:1 -TARGET_OUT_GRID:${TMP_DIR}/out_$i.sgrd

	fi

	i=`expr $i + 1` 	
	j=`expr $i - 1`

done < ${TMP_DIR}/list_sort



