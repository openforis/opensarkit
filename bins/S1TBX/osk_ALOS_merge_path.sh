#! /bin/bash


PROC_DIR=/media/avollrath/phd_data2/FAO/Studies/Ecuador/Mainland/FBD/2009

cd ${PROC_DIR}
# Loop for Satellite Track
for SAT_TRACK in `ls -1 -d [1-9]*`
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
				#	gdalwarp -overwrite -of SAGA -srcnodata "0" -dstnodata "-99999" ${FILE} ${BNAME}"_saga".sdat
	

					echo "Fill holes with less than 5000 pixels using IDW for ${FRAME} ${SAT_TRACK} ${DATASET}"				
					#saga_cmd -f=r grid_tools 25 -GRID:${BNAME}"_saga.sgrd" -MAXGAPCELLS:500 -MAXPOINTS:1000 -LOCALPOINTS:25 -CLOSED:${FRAME}"_"${BNAME}"_filled.sgrd"

				done
		
					PWD=`pwd`
					MOSAIC_INPUT=`ls -1 *_filled.sgrd`
	
					echo "${MOSAIC_INPUT}" > tmp.test
					echo "${MOSAIC_INPUT}"
					if grep -q Gamma0_HH tmp.test;then
					
						GREP_HH=`grep Gamma0_HH tmp.test`
						echo ${PWD}/${GREP_HH} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HH_list"
					fi

					if grep -q Gamma0_HV tmp.test;then

						GREP_HV=`grep Gamma0_HV tmp.test`
						echo ${PWD}/${GREP_HV} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HV_list"
					fi					
	
					if grep -q HH_HV tmp.test;then
 	
						GREP_HHHV=`grep HH_HV tmp.test`
						echo ${PWD}/${GREP_HHHV} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_HH_HV_list"
	
					fi

					rm tmp.test

				fi


			cd ../
			done
		cd ../
		done

	cd ../
	done

	
	LIST_HH=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_list"`
	#saga_cmd grid_tools 3 -GRIDS:${LIST_HH} -TYPE:7 -OVERLAP:5 -BLEND_DIST:10 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}"_Gamma0_HH.sgrd"

	LIST_HV=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_list"`
	#saga_cmd grid_tools 3 -GRIDS:${LIST_HV} -TYPE:7 -OVERLAP:5 -BLEND_DIST:10 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}"_Gamma0_HV.sgrd"

	LIST_HHHV=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_HH_HV_list"`
	#saga_cmd grid_tools 3 -GRIDS:${LIST_HHHV} -TYPE:7 -OVERLAP:5 -BLEND_DIST:10 -TARGET_OUT_GRID:${PROC_DIR}/${SAT_TRACK}"_HHHV_ratio.sgrd"

	gdal_merge.py -n -99999 -a_nodata -99999 -separate -of GTiff -o ${PROC_DIR}/${SAT_TRACK}"_HH_HV_HHHV_ratio.tif" ${PROC_DIR}/${SAT_TRACK}"_Gamma0_HH.sdat" ${PROC_DIR}/${SAT_TRACK}"_Gamma0_HV.sdat" ${PROC_DIR}/${SAT_TRACK}"_HHHV_ratio.sdat"

	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HHHV_list"


	cd ${PROC_DIR}
done
