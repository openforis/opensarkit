#! /bin/bash


# TMP sourcing for Sepal env.
source /data/home/Andreas.Vollrath/github/OpenSARKit_source.bash

#----------------------------------------------------------------------
#	0 Set up Script variables
#----------------------------------------------------------------------

# 	0.1 Check for right usage
if [ "$#" != "1" ]; then
  echo -e "Usage: osk_ALOS_merge_path /path/to/satellite/tracks"
  echo -e "The path will be your Project folder!"
  exit 1
else
  cd $1
  export PROC_DIR=`pwd`
  echo "Welcome to OpenSARKit!"
  echo "Processing folder: ${PROC_DIR}"
fi

cd ${PROC_DIR}
# Loop for Satellite Track
for SAT_TRACK in `ls -1 -d [0-9]*`
do
	cd ${SAT_TRACK}
	
	# Loop for Acquisition Date
	for ACQ_DATE in `ls -1 -d [1,2]*`
	do 

		cd ${ACQ_DATE}

		# Loop for Frames
		for FRAME in `ls -1`
		do 

			cd $FRAME
	
			for DATASET in `ls -1 -d *data`
			do 


				echo "${DATASET}" > tmp_datatest
				if grep -q L.1.1.data tmp_datatest;then
				echo "original dataset"
				else

				cd ${DATASET}

				#rm -f *.sgrd *.sdat *.prj *.mgrd *.xml
 				for FILE in `ls -1 *.img`
				do
					


					BNAME=`echo $FILE | rev | cut -c 5- | rev`
					#echo $FILE
					#echo $BNAME
  					echo "Translate to SAGA GIS format (powerful and fast raster manipulation)"				
					gdalwarp -overwrite -of SAGA -srcnodata "0" -dstnodata "-99999" ${FILE} ${BNAME}"_saga".sdat
	

					#echo "Fill holes with less than 5000 pixels using IDW for ${FRAME} ${SAT_TRACK} ${DATASET}"				
					#saga_cmd -f=r grid_tools 25 -GRID:${BNAME}"_saga.sgrd" -MAXGAPCELLS:500 -MAXPOINTS:1000 -LOCALPOINTS:25 -CLOSED:${FRAME}"_"${BNAME}"_filled.sgrd"

				done
		
					PWD=`pwd`
					MOSAIC_INPUT=`ls -1 *_saga.sgrd`
	
					echo "${MOSAIC_INPUT}" > tmp.test
					echo "${MOSAIC_INPUT}"
					if grep -q Gamma0_HH_saga tmp.test;then
					
						GREP_HH=`grep Gamma0_HH_saga tmp.test`
						echo ${PWD}/${GREP_HH} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HH_list"
					fi

					if grep -q Gamma0_HV_saga tmp.test;then

						GREP_HV=`grep Gamma0_HV_saga tmp.test`
						echo ${PWD}/${GREP_HV} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HV_list"
					fi					
	
					if grep -q Gamma0_HH_db tmp.test;then
					
						GREP_HH=`grep Gamma0_HH_db tmp.test`
						echo ${PWD}/${GREP_HH} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HH_db_list"
					fi

					if grep -q Gamma0_HV_db tmp.test;then

						GREP_HV=`grep Gamma0_HV_db tmp.test`
						echo ${PWD}/${GREP_HV} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HV_db_list"
					fi					
				
					#if grep -q Alpha tmp.test;then
 	
					#	GREP_ALPHA=`grep Alpha tmp.test`
					#	echo ${PWD}/${GREP_ALPHA} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Alpha_list"
	
					#fi

					#if grep -q Entropy tmp.test;then
 	
					#	GREP_ENTROPY=`grep Entropy tmp.test`
					#	echo ${PWD}/${GREP_ENTROPY} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Entropy_list"
	
					#fi

					#if grep -q Anisotropy tmp.test;then
 	
					#	GREP_ANISOTROPY=`grep Anisotropy tmp.test`
					#	echo ${PWD}/${GREP_ANISOTROPY} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Anisotropy_list"
	
					#fi


					#if grep -q HH_speckle_divergence tmp.test;then
 	
					#	GREP_HH_SPK_DIV=`grep HH_speckle_divergence tmp.test`
					#	echo ${PWD}/${GREP_HH_SPK_DIV} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HH_speckle_divergence_list"
	
					#fi

					#if grep -q HV_speckle_divergence tmp.test;then
 	
					#	GREP_HV_SPK_DIV=`grep HV_speckle_divergence tmp.test`
					#	echo ${PWD}/${GREP_HV_SPK_DIV} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HV_speckle_divergence_list"
	
					#fi
				
					if echo $DATASET | grep -q TEXTURE_HH;then 

						if grep -q Dissimilarity tmp.test;then
 	
							GREP_HH_DISS=`grep Dissimilarity tmp.test`
							echo ${PWD}/${GREP_HH_DISS} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HH_Dissimilarity_list"
	
						fi

						if grep -q Homogeneity tmp.test;then
 	
							GREP_HH_HOMO=`grep Homogeneity tmp.test`
							echo ${PWD}/${GREP_HH_HOMO} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HH_Homogeneity_list"
	
						fi

						if grep -q Energy tmp.test;then
 	
							GREP_HH_ENER=`grep Energy tmp.test`
							echo ${PWD}/${GREP_HH_ENER} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HH_Energy_list"
		
						fi


						if grep -q GLCMMean tmp.test;then
 	
							GREP_HH_MEAN=`grep GLCMMean tmp.test`
							echo ${PWD}/${GREP_HH_MEAN} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HH_GLCMMean_list"
	
						fi

						if grep -q GLCMVariance tmp.test;then
 	
							GREP_HH_VAR=`grep GLCMVariance tmp.test`
							echo ${PWD}/${GREP_HH_VAR} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HH_GLCMVariance_list"
	
						fi

					elif echo $DATASET | grep -q TEXTURE_HV;then 

						if grep -q Dissimilarity tmp.test;then
 	
							GREP_HV_DISS=`grep Dissimilarity tmp.test`
							echo ${PWD}/${GREP_HV_DISS} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HV_Dissimilarity_list"
	
						fi

						if grep -q Homogeneity tmp.test;then
 	
							GREP_HV_HOMO=`grep Homogeneity tmp.test`
							echo ${PWD}/${GREP_HV_HOMO} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HV_Homogeneity_list"
	
						fi

						if grep -q Energy tmp.test;then
 	
							GREP_HV_ENER=`grep Energy tmp.test`
							echo ${PWD}/${GREP_HV_ENER} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HV_Energy_list"
	
						fi


						if grep -q GLCMMean tmp.test;then
 	
							GREP_HV_MEAN=`grep GLCMMean tmp.test`
							echo ${PWD}/${GREP_HV_MEAN} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HV_GLCMMean_list"
	
						fi

						if grep -q GLCMVariance tmp.test;then
 	
							GREP_HV_VAR=`grep GLCMVariance tmp.test`
							echo ${PWD}/${GREP_HV_VAR} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HV_GLCMVariance_list"
	
						fi
				
					rm tmp.test

					fi	
				fi
				
			cd ../
			done

		cd ../
		done

	cd ../
	done

	mkdir -p ${PROC_DIR}/PATH_MOSAICS


	# Mosaicing
	LIST_HH=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_list"`
	saga_cmd grid_tools 3 -GRIDS:${LIST_HH} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${DATE}"_Gamma0_HH.sgrd"

	LIST_HV=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_list"`
	saga_cmd grid_tools 3 -GRIDS:${LIST_HV} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${DATE}"_Gamma0_HV.sgrd"

	LIST_HH_DB=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_db_list"`
	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_DB} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${DATE}"_Gamma0_HH_db.sgrd"

	LIST_HV_DB=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_db_list"`
	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_DB} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${DATE}"_Gamma0_HV_db.sgrd"

	LIST_HH_DISS=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_Dissimilarity_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_DISS} -TYPE:7 -OVERLAP:2 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_Dissimilarity.sgrd"

	LIST_HH_HOMO=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_Homogeneity_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_HOMO} -TYPE:7 -OVERLAP:2 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_Homogeneity.sgrd"

	LIST_HH_ENER=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_Energy_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_ENER} -TYPE:7 -OVERLAP:2 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_Energy.sgrd"

	LIST_HH_MEAN=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_GLCMMean_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_MEAN} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_GLCMMean.sgrd"

	LIST_HH_VAR=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_GLCMVariance_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_VAR} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_GLCMVariance.sgrd"

	LIST_HV_DISS=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_Dissimilarity_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_DISS} -TYPE:7 -OVERLAP:2 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_Dissimilarity.sgrd"

	LIST_HV_HOMO=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_Homogeneity_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_HOMO} -TYPE:7 -OVERLAP:2 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_Homogeneity.sgrd"

	LIST_HV_ENER=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_Energy_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_ENER} -TYPE:7 -OVERLAP:2 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_Energy.sgrd"

	LIST_HV_MEAN=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_GLCMMean_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_MEAN} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_GLCMMean.sgrd"

	LIST_HV_VAR=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_GLCMVariance_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_VAR} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -MATCH:1 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_GLCMVariance.sgrd"

#	LIST_ALPHA=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Alpha_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_ALPHA} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Alpha.sgrd"

#	LIST_ENTROPY=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Entropy_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_ENTROPY} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Entropy.sgrd"

#	LIST_ANISOTROPY=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Anisotropy_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_ANISOTROPY} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Anisotropy.sgrd"

#	LIST_HH_SPK_DIV=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_speckle_divergence_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_SPK_DIV} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_SPK_DIV.sgrd"

#	LIST_HV_SPK_DIV=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_speckle_divergence_list"`
#	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_SPK_DIV} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_SPK_DIV.sgrd"


	# Calculate ratio 
#	saga_cmd grid_calculus 1 -GRIDS:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HH.sgrd" -XGRIDS:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HV.sgrd" -RESULT:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_HV_ratio.sgrd" -FORMULA:"a / b"

#	saga_cmd grid_calculus 1 -GRIDS:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HH_db.sgrd" -XGRIDS:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HV_db.sgrd" -RESULT:${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_HV_ratio_db.sgrd" -FORMULA:"a / b"

	# Merge HH_HV
	mkdir ${PROC_DIR}/PATH_MOSAICS

#	gdal_merge.py -n -99999 -a_nodata -99999 -separate -of SAGA -o ${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${ACQ_DATE}"_HH_HV_HHHVratio.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HH.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HV.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_HV_ratio.sdat"

#	gdal_merge.py -n -99999 -a_nodata -99999 -separate -of SAGA -o ${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${ACQ_DATE}"_HH_HV_HHHVratio_db.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HH_db.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Gamma0_HV_db.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_HV_ratio_db.sdat"

#	gdal_merge.py -n -99999 -a_nodata -99999 -separate -of SAGA -o ${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${ACQ_DATE}"_TEXTURE.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_Dissimilarity.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_Homogeneity.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_Energy.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_GLCMMean.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_GLCMVariance.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_Dissimilarity.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_Homogeneity.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_Energy.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_GLCMMean.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_GLCMVariance.sdat"

#	gdal_merge.py -n -99999 -a_nodata -99999 -separate -of GTiff -o ${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${ACQ_DATE}"_H_A_alpha.tif" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Entropy.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Anisotropy.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_Alpha.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HH_SPK_DIV.sdat" ${PROC_DIR}/${SAT_TRACK}/PATH_MOSAIC/${SAT_TRACK}"_HV_SPK_DIV.sdat"


	# remove lists
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_db_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_db_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Alpha_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Entropy_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Anisotropy_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_speckle_divergence_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_speckle_divergence_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_Dissimilarity_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_Homogeneity_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_Energy_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_GLCMVariance_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_GLCMMean_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_Dissimilarity_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_Homogeneity_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_Energy_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_GLCMMean_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HV_GLCMVariance_list"


	cd ${PROC_DIR}
done




