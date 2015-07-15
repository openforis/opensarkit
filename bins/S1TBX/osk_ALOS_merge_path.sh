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
	

				done
		
					PWD=`pwd`
					MOSAIC_INPUT=`ls -1 *_saga.sgrd`
	
					echo "${MOSAIC_INPUT}" > tmp.test
					echo "${MOSAIC_INPUT}"
			
	
					if grep -q Gamma0_HH_db tmp.test;then
					
						GREP_HH=`grep Gamma0_HH_db tmp.test`
						echo ${PWD}/${GREP_HH} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HH_db_list"
					fi

					if grep -q Gamma0_HV_db tmp.test;then

						GREP_HV=`grep Gamma0_HV_db tmp.test`
						echo ${PWD}/${GREP_HV} | tr '\n' ';' >> ${PROC_DIR}/tmp_${SAT_TRACK}"_Gamma0_HV_db_list"
					fi					
				

					fi	
				fi
				
			cd ../
			done

		cd ../
		done

	cd ../
	done

	mkdir -p ${PROC_DIR}/PATH_MOSAICS


	LIST_HH_DB=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_db_list"`
	saga_cmd grid_tools 3 -GRIDS:${LIST_HH_DB} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${DATE}"_Gamma0_HH_db.sgrd"

	LIST_HV_DB=`cat ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_db_list"`
	saga_cmd grid_tools 3 -GRIDS:${LIST_HV_DB} -TYPE:7 -OVERLAP:3 -BLEND_DIST:0 -TARGET_OUT_GRID:${PROC_DIR}/PATH_MOSAICS/${SAT_TRACK}"_"${DATE}"_Gamma0_HV_db.sgrd"

	# remove lists
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HH_db_list"
	rm ${PROC_DIR}/"tmp_"${SAT_TRACK}"_Gamma0_HV_db_list"

	cd ${PROC_DIR}
done




