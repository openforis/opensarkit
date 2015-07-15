#! /home/avollrath/miniconda/bin/python

#conda install -c osgeo rsgis_scripts rsgislib kealib scikit-learn rios


import rsgislib
from rsgislib import imagecalc
from rsgislib import imageutils

# inputs 
dem = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/DEM.kea'
aspect = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/DEM_aspect.kea'
slope = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/DEM_slope.kea'
inFileHH = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/GAMMA0_HH_db_mosaic_filtered.kea'
inFileHV = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/GAMMA0_HV_db_mosaic_filtered.kea'
inFile_Mean_HH = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/GLCMMean_HH.kea'
inFile_Mean_HV = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/GLCMMean_HV.kea'
inFile_Var_HH = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/GLCMVariance_HH.kea'
inFile_Var_HV = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/GLCMVariance_HV.kea'

#	print inFileHH

# outputs
# HH/HV ratio
outFileHHHV = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/out_hhhv_ratio.kea'
outStackInt = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/out_hhhv_ratio_stack.kea'
outStackInt_stretch = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/Mosaic_stack_stretch.kea'

# calculate ratio
bandDefns = [imagecalc.BandDefn('hh', inFileHH, 1),
             imagecalc.BandDefn('hv', inFileHV, 1)]
imagecalc.bandMath(outFileHHHV, 'hh/hv', 'KEA', rsgislib.TYPE_32FLOAT, bandDefns) 


# create image stack
bands_list = [inFileHH, inFileHV, outFileHHHV] #, inFile_Mean_HH, inFile_Mean_HV, inFile_Var_HH, inFile_Var_HV] #, dem, aspect, slope]
band_names = ['HH','HV', 'HH_HV'] # , 'Mean_HH', 'Mean_HV', 'Var_HH', 'Var_HV']    #, 'dem', 'aspect', 'slope']
gdaltype = rsgislib.TYPE_32FLOAT
imageutils.stackImageBands(bands_list, band_names, outStackInt, None, 
                                    0, 'KEA', rsgislib.TYPE_32FLOAT) 

# stretch image
imageutils.stretchImage(outStackInt, outStackInt_stretch, False, '', True, False, 'GTiff', rsgislib.TYPE_8INT, imageutils.STRETCH_LINEARSTDDEV, 2)

#rsgislibsegmentation.py --input outStackInt --output '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_25.kea' --outmeanimg '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_mean_25.kea' -t /tmp --numclusters 15 --minpxls 25
#clumpsFile_100 = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_100.kea'
#meanImage_100 = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_mean_100.kea'
#rsgislibsegmentation.py --input outStackInt --output Out_100	 --outmeanimg OutMean_100 -t /tmp --numclusters 100 --minpxls 100
#segutils.runShepherdSegmentation(outStackInt, clumpsFile_100,
#                    meanImage_100, numClusters=100, minPxls=100)
