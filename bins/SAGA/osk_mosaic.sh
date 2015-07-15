#! /bin/bash

#normalize in the range of -30 - 5

#for log file (i.e. 0.001 - 5)
PROC_DIR=$1

echo "mosaicing the paths"
cd ${PROC_DIR}
TMP_DIR=${PROC_DIR}/TMP
FINAL=${PROC_DIR}/FINAL_MOSAIC
mkdir -p ${FINAL}
mkdir -p $TMP_DIR

for line in `ls -1 *Gamma0_HH_db.sdat`;do 
	gdal_calc.py -A $line --outfile ${PROC_DIR}/tmp1.tif --calc="A*(A>-30)" --NoDataValue=-99999
	gdal_calc.py -A ${PROC_DIR}/tmp1.tif  --outfile ${PROC_DIR}/tmp2.tif --calc="A*(A<5)" --NoDataValue=-99999
	gdal_translate -of SAGA ${PROC_DIR}/tmp2.tif ${PROC_DIR}/end_$line
	rm -f tmp*
done 
LIST_GAMMA_HH=`ls -1 end*Gamma0_HH_db.sgrd | tr '\n' ';'`
saga_cmd grid_tools 3 -GRIDS:${LIST_GAMMA_HH} -TYPE:7 -OVERLAP:6 -BLEND_DIST:10	 -MATCH:1 -TARGET_OUT_GRID:${FINAL}/GAMMA0_HH_db_mosaic.sgrd
rm -rf end*


for line in `ls -1 *Gamma0_HV_db.sdat`;do 
	gdal_calc.py -A $line --outfile ${PROC_DIR}/tmp1.tif --calc="A*(A>-30)" --NoDataValue=-99999
	gdal_calc.py -A ${PROC_DIR}/tmp1.tif  --outfile ${PROC_DIR}/tmp2.tif --calc="A*(A<5)" --NoDataValue=-99999
	gdal_translate -of SAGA ${PROC_DIR}/tmp2.tif ${PROC_DIR}/end_$line
	rm -f tmp*
done 
LIST_GAMMA_HV=`ls end*Gamma0_HV_db.sgrd | tr '\n' ';'`
saga_cmd grid_tools 3 -GRIDS:${LIST_GAMMA_HV} -TYPE:7 -OVERLAP:6 -BLEND_DIST:10 -MATCH:1 -TARGET_OUT_GRID:${FINAL}/GAMMA0_HV_db_mosaic.sgrd
rm -rf end*

# HH
#saga_cmd grid_filter 3 -INPUT:${FINAL}/GAMMA0_HH_db_mosaic.sgrd -RESULT:${FINAL}/GAMMA0_HH_db_mosaic_filtered.sgrd -NOISE_ABS:5 -NOISE_REL:3 -METHOD:1

# HV
#saga_cmd grid_filter 3 -INPUT:${FINAL}/GAMMA0_HV_db_mosaic.sgrd -RESULT:${FINAL}/GAMMA0_HV_db_mosaic_filtered.sgrd -NOISE_ABS:5 -NOISE_REL:3 -METHOD:1


# HH/HV
#saga_cmd grid_calculus 1 -GRIDS:${FINAL}/GAMMA0_HH_db_mosaic.sdat -XGRIDS:${FINAL}/GAMMA0_HV_db_mosaic.sdat -RESULT:${FINAL}/HH_HV_db_mosaic.sdat -FORMULA:"a / b"
#saga_cmd grid_calculus 1 -GRIDS:${FINAL}/GAMMA0_HH_db_mosaic_filtered.sdat -XGRIDS:${FINAL}/GAMMA0_HV_db_mosaic_filtered.sdat -RESULT:${FINAL}/HH_HV_db_mosaic_filtered.sdat -FORMULA:"a / b"


# HH texture calculations
gdalwarp -srcnodata -99999 -dstnodata 0 ${FINAL}/GAMMA0_HH_db_mosaic.sdat ${FINAL}/GAMMA0_HH_db_mosaic2.tif
# define path/name of output
INPUT_HH=${FINAL}/GAMMA0_HH_db_mosaic2.tif
INPUT_HV=${FINAL}/GAMMA0_HV_db_mosaic2.tif

OUTPUT_TEXTURE_HH=${FINAL}/TEXTURE_HH.dim
OUTPUT_TEXTURE_HV=${FINAL}/TEXTURE_HV.dim

# Write new xml graph and substitute input and output files
cp ${S1TBX_GRAPHS}/Generic_Texture.xml ${TMP_DIR}/TEXTURE_HH.xml
	
# insert Input file path into processing chain xml
sed -i "s|INPUT_TR|${INPUT_HH}|g" ${TMP_DIR}/TEXTURE_HH.xml
# insert Input file path into processing chain xml
sed -i "s|OUTPUT_TR|${OUTPUT_TEXTURE_HH}|g" ${TMP_DIR}/TEXTURE_HH.xml

echo "Calculate GLCM Texture measurements for HH channel"
sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml 2>&1 | tee  ${TMP_DIR}/tmplog

# in case it fails try a second time	
if grep -q Error ${TMP_DIR}/tmplog; then 	
	echo "2nd try"
	rm -rf ${FINAL_DIR}/TEXTURE_HH.dim ${FINAL_DIR}/TEXTURE_HH.data
	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HH.xml
fi

gdalwarp -srcnodata -99999 -dstnodata 0 ${FINAL}/GAMMA0_HV_db_mosaic.sdat ${FINAL}/GAMMA0_HV_db_mosaic2.tif
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
	rm -rf ${FINAL_DIR}/TEXTURE_HV.dim ${FINAL_DIR}/TEXTURE_HV.data
	sh ${S1TBX_EXE} ${TMP_DIR}/TEXTURE_HV.xml
fi


rm -rf ${TMP_DIR}
